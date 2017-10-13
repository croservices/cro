use Cro::Tools::CroFile;
use Cro::Tools::Services;

class Cro::Tools::Runner {
    role Message {
        has $.service-id;
    }

    class Started does Message {
        has $.cro-file;
        has %.endpoint-ports;
    }

    class Restarted does Message {
        has $.cro-file;
    }

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

    has Cro::Tools::Services $.services is required;
    has $.service-id-filter = *;
    has Bool $.trace = False;
    has Str @.trace-filters;
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
        has Bool $.tracing;
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
    method traceFlip($service-id) {
        $!trace = !$!trace;
        my $restarted = Promise.new;
        self.restart($service-id, :$restarted);
        # XXX fix
        await Promise.in(1);
        $!trace = !$!trace;
    }

    method run(--> Supply) {
        my %services;

        supply {
            sub enable-service($proc, $service, %endpoint-ports, %env) {
                my $path = $service.path;
                my $cro-file = $service.cro-file;

                for $cro-file.links -> $link {
                    with $link.host-env {
                        %env{$_} = 'localhost'
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
                    whenever $service.metadata-changed.merge($service.source-changed).stable(1) {
                        %services{$cro-file.id}.cro-file = $service.cro-file;
                        restart-service(%services{$cro-file.id});
                    }
                    %services{$cro-file.id}.state = StartedState;
                    emit Started.new(service-id => $cro-file.id, :$cro-file, :%endpoint-ports);
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

            whenever $!services.services -> $service {
                FIRST {
                    whenever Promise.in(2) {
                        for %services.grep(*.value.state == WaitingState) {
                            emit UnableToStart.new(service-id => .cro-file.id,
                                                   cro-file => .cro-file);
                        }
                    }
                }

                my $cro-file = $service.cro-file;
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

            whenever $!commands.Supply -> %command {
                given %command<action> {
                    when 'stop' {
                        # TODO: improve
                        %services{%command<id>}.proc.kill(SIGINT);
                    }
                    when 'start' {
                        given (%services{%command<id>}) {
                            (.proc, my %env) = service-proc(.cro-file, .endpoint-ports);
                            .proc-exit = .proc.start(:ENV(%env), :cwd(.path));
                            emit Started.new(service-id => .cro-file.id, cro-file => .cro-file,
                                             endpoint-ports => .endpoint-ports)
                        }
                    }
                    when 'restart' {
                        my $service = %services{%command<id>};
                        restart-service($service);
                    }
                }
            }

            sub restart-service($service) {
                try $service.proc.kill(SIGINT);
                whenever $service.proc-exit {
                    given $service {
                        (.proc, my %env) = service-proc(.cro-file, .endpoint-ports);
                        .proc-exit = .proc.start(:ENV(%env), :cwd(.path))
                    }
                    emit Restarted.new:
                        service-id => $service.cro-file.id,
                        cro-file => $service.cro-file;
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
                    my $try-conn = IO::Socket::Async.connect('localhost', $next-try-port);
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

            sub service-proc($cro-file, %endpoint-ports) {
                my $service-id = $cro-file.id;
                my %env = %*ENV;
                for $cro-file.endpoints -> $endpoint {
                    with $endpoint.host-env {
                        %env{$_} = 'localhost';
                    }
                    with $endpoint.port-env {
                        %env{$_} = %endpoint-ports{$endpoint.id};
                    }
                }
                if $!trace {
                    %env<CRO_TRACE> = '1';
                    %env<CRO_TRACE_MACHINE_READABLE> = '1';
                }
                my $proc = Proc::Async.new('perl6', '-Ilib', $cro-file.entrypoint);
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
