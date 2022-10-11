use Cro::Tools::CroFile;
use Cro::Tools::Services;

class Cro::Tools::Runner {
    role Message {
        has $.service-id;
    }

    role ServiceMessage does Message {
        has $.cro-file;
        has $.tracing;
    }

    class Started does ServiceMessage {
        has %.endpoint-ports;
    }

    class Restarted does ServiceMessage {
        has $.cause;
    }
    class Stopped does ServiceMessage {}

    class Output does Message {
        has Bool $.on-stderr;
        has Str $.line;
    }

    class Trace does Message {
        has Str $.id;
        has Str $.component;
        has Str $.event;
        has Str $.data;
    }
    class UnableToStart does Message {
        has $.cro-file;
    }
    class BadCroFile does Message {
        has IO::Path $.path;
        has Exception $.exception;
    }
    class PossiblyNoCroConfig does Message {
        has Str $.directory;
    }

    has Cro::Tools::Services $.services is required;
    has $.service-id-filter = *;
    has Bool $.trace = False;
    has Str @.trace-filters;
    has Str:D $.host = 'localhost';
    has Supplier $!commands = Supplier.new;

    my enum State (StartedState => 1, WaitingState => 0, StoppedState => -1);

    my class Service {
        has $.path;
        has $.proc is rw;
        has $.proc-exit is rw;
        has $.cro-file is rw;
        has $.service;
        has %.endpoint-ports;
        has %.env;
        has State $.state is rw;
        has Bool $.tracing is rw;
        has @.dependencies;
    }

    method stop($service-id) {
        $!commands.emit({action => 'stop', id => $service-id});
    }
    method start($service-id) {
        $!commands.emit({action => 'start', id => $service-id});
    }
    method restart($service-id) {
        $!commands.emit({action => 'restart', id => $service-id});
    }
    method trace($service-id, $command) {
        $!commands.emit({action => 'trace', :$command, id => $service-id})
    }
    method trace-all($command) {
        $!commands.emit({action => 'trace-all', :$command});
    }

    method run(--> Supply) {
        my %services;

        supply {
            sub enable-service($proc, $service, %endpoint-ports, %env) {
                my $path = $service.path;
                my $cro-file = $service.cro-file;

                for $cro-file.links -> $link {
                    with $link.host-env {
                        %env{$_} = $!host;
                    }
                    with $link.port-env {
                        my $port = %services{$link.service}.endpoint-ports{$link.endpoint};
                        unless $port {
                            my $line = "There is no endpoint {$link.endpoint} in {$link.service}";
                            emit Output.new(service-id => $service.cro-file.id, :on-stderr, :$line);
                        }
                        %env{$_} = $port;
                    }
                }

                my $proc-exit = $proc.start(:ENV(%env), :cwd($path));
                %services{$cro-file.id} = Service.new(
                    :$path, :$proc, :$proc-exit, :$cro-file,
                    :$service, :%endpoint-ports, :%env, state => WaitingState,
                    tracing => $!trace
                );

                whenever $proc.ready {
                    whenever $service.metadata-changed.merge($service.source-changed).stable(1) -> $path {
                        %services{$cro-file.id}.cro-file = $service.cro-file;
                        restart-service(%services{$cro-file.id}, "change to $path");
                    }
                    %services{$cro-file.id}.state = StartedState;
                    emit Started.new(service-id => $cro-file.id, :$cro-file, :%endpoint-ports, tracing => $!trace);
                    # Enable services that rely on current
                    my %splitted = %services.List.classify({ .value.state });
                    my $wait = %splitted<WaitingState> // ();
                    $wait .= map(*.value);
                    my $started = %splitted<StartedState>.map(*.key);
                    for @$wait {
                        if .dependencies ⊆ $started.Set {
                            # Recursive scheme
                            enable-service(.proc,
                                           .service,
                                           .endpoint-ports,
                                           .env);
                            $started = %services.List.grep(*.value.state == StartedState).map(*.key);
                        }
                    }
                }
            }

            my $first-service = Promise.new;
            whenever $first-service {
                whenever Promise.in(2) {
                    for %services.grep(*.value.state == WaitingState) {
                        emit UnableToStart.new(service-id => .value.cro-file.id,
                                               cro-file => .value.cro-file);
                    }
                }
            }

            whenever Promise.in(5) {
                if %services.elems == 0 {
                    emit PossiblyNoCroConfig.new(directory => $!services.base-path.Str);
                }
            }

            whenever $!services.services -> $service {
                $first-service.keep unless $first-service.status ~~ Kept;
                with $service.cro-file -> $cro-file {
                    my $service-id = $cro-file.id;
                    if $service-id ~~ $!service-id-filter {
                        my %endpoint-ports = assign-ports($cro-file.endpoints);
                        my ($proc, %env) = service-proc($cro-file, %endpoint-ports);
                        if $cro-file.links == 0
                        || $cro-file.links».service ⊆ %services.keys {
                            # No dependencies, just start it
                            enable-service($proc, $service, %endpoint-ports, %env);
                        } else {
                            my @dependencies = $cro-file.links.grep({ !%services{.service} })>>.service.List;
                            %services{$service-id} = Service.new(
                                path => $service.path,
                                :$proc, :$cro-file,
                                :$service, :%endpoint-ports,
                                :%env, state => WaitingState,
                                tracing => $!trace, :@dependencies);
                        }
                    }
                }
                else {
                    emit BadCroFile.new(:path($service.path), :exception($service.cro-file-error));
                }
            }

            whenever $!commands.Supply -> %command {
                given %command<action> {
                    when 'stop' {
                        $_ = %services{%command<id>};
                        unless .state == StoppedState {
                            .state = StoppedState;
                            .proc.kill(SIGINT);
                            emit Stopped.new(service-id => .cro-file.id, cro-file => .cro-file, tracing => .tracing);
                        }
                    }
                    when 'start' {
                        $_ = %services{%command<id>};
                        if .state == StoppedState {
                            .state = StartedState;
                            (.proc, my %env) = service-proc(.cro-file, .endpoint-ports, trace => .tracing);
                            .proc-exit = .proc.start(:ENV(%env), :cwd(.path));
                            emit Started.new(service-id => .cro-file.id, cro-file => .cro-file,
                                             endpoint-ports => .endpoint-ports, tracing => .tracing)
                        }
                    }
                    when 'restart' {
                        my $service = %services{%command<id>};
                        restart-service($service, 'explicitly requested');
                    }
                    when 'trace' {
                        my $service = %services{%command<id>};
                        if $service.tracing ^^ (%command<command> eq 'on') {
                            $service.tracing = !$service.tracing;
                            restart-service($service, 'tracing enabled') if $service.state != StoppedState;
                        }
                    }
                    when 'trace-all' {
                        for %services.keys -> $s {
                            $s.tracing = %command<command> eq 'on';
                            restart-service($s, 'tracing enabled') if $s.state != StoppedState;
                        }
                    }
                }
            }

            sub restart-service($service, $cause) {
                try $service.proc.kill(SIGINT);
                whenever $service.proc-exit {
                    given $service {
                        (.proc, my %env) = service-proc(.cro-file, .endpoint-ports, trace => .tracing);
                        .proc-exit = .proc.start(:ENV(%env), :cwd(.path));
                        emit Restarted.new:
                            service-id => $service.cro-file.id,
                            cro-file => $service.cro-file,
                            tracing => .tracing,
                            cause => $cause;
                    }
                }
            }

            CLOSE {
                for %services.values {
                    .proc.kill(SIGINT) if .state == StartedState;
                }
            }

            sub assign-ports(@endpoints) {
                hash @endpoints.map({ .id => free-port() })
            }

            my $next-try-port = 20000;
            sub free-port() {
                loop {
                    my $try-conn = IO::Socket::Async.connect($!host, $next-try-port);
                    await Promise.anyof($try-conn, Promise.in(1));
                    if $try-conn.status == Kept {
                        $try-conn.result.close;
                        $next-try-port++;
                        if $next-try-port > 60000 {
                            $next-try-port = 20000;
                        }
                    }
                    else {
                        return $next-try-port++;
                    }
                }    
            }

            sub service-proc($cro-file, %endpoint-ports, :$trace) {
                my $service-id = $cro-file.id;
                my %env = %*ENV;
                for $cro-file.env -> $_ { %env{.name} = .value }
                for $cro-file.endpoints -> $endpoint {
                    with $endpoint.host-env {
                        %env{$_} = $!host;
                    }
                    with $endpoint.port-env {
                        %env{$_} = %endpoint-ports{$endpoint.id};
                    }
                }
                if $trace // $!trace {
                    %env<CRO_TRACE> = '1';
                    %env<CRO_TRACE_MACHINE_READABLE> = '1';
                }
                my $proc = Proc::Async.new($*EXECUTABLE.absolute,'-Ilib', $cro-file.entrypoint);
                whenever $proc.stdout.lines -> $line {
                    emit Output.new(:$service-id, :!on-stderr, :$line);
                }
                whenever $proc.stderr.lines -> $line {
                    if $line ~~ &trace-parser {
                        if @!trace-filters {
                            my $lc-component = $<component>.lc;
                            next unless $lc-component.contains(any(@!trace-filters));
                        }
                        emit Trace.new:
                            :$service-id, :component(~$<component>),
                            :id($<id>.substr(1, *-1)), :event(~$<event>),
                            :data($<data> ?? decode(~$<data>) !! Nil);
                    }
                    else {
                        emit Output.new(:$service-id, :on-stderr, :$line);
                    }
                }
                ($proc, %env);
            }
        }
    }

    my token trace-parser {
        ^
        '[TRACE' $<id>=[<-[\]]>+] ']'
        \s+
        $<component>=[\S+]
        \s+
        $<event>=[\S+]
        [
            \s+
            $<data>=[.+]
        ]?
    }

    sub decode($_) {
        .subst('\\n', "\n", :g).subst('\\\\', '\\', :g)
    }
}
