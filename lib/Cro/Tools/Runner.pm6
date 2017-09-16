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

    has Cro::Tools::Services $.services is required;
    has $.service-id-filter = *;
    has Bool $.trace = False;
    has Str @.trace-filters;

    my enum State (started => 1, waiting => 0);

    class ServiceStatus {
        has $.proc,
        has $.service,
        has %.endpoint-ports;
        has %.env;
        has State $.state is rw;
        has @.dependencies;
    }

    method run(--> Supply) {
        my %services;

        supply {
            my class RunningService {
                has $.path;
                has %.endpoint-ports;
                has $.proc is rw;
                has $.proc-exit is rw;
                has $.cro-file is rw;
            }
            my %running-services;

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
                            warn "{$service.cro-file.id}: There is no endpoint {$link.endpoint} in {$link.service}";
                        }
                        %env{$_} = $port;
                    }
                }

                my $proc-exit = $proc.start(:ENV(%env), :cwd($path));
                %services{$cro-file.id} = ServiceStatus.new(
                    :$service, state => started, :%endpoint-ports
                );

                whenever $proc.ready {
                    add-service $service, RunningService.new:
                                          :$path, :%endpoint-ports, :$proc, :$proc-exit, :$cro-file;
                    emit Started.new(service-id => $cro-file.id, :$cro-file, :%endpoint-ports);
                    # Enable services that rely on current
                    my %splitted = %services.List.classify({ .value.state });
                    my $wait = %splitted<waiting>;
                    my $started = %splitted<started>.map(*.key);
                    for @$wait {
                        last unless $_;
                        $_ .= value;
                        if .dependencies ⊆ $started.Set {
                            # Recursive scheme
                            enable-service(.proc,
                                           .service,
                                           .endpoint-ports,
                                           .env);
                            $started = %services.List.grep(*.value.state == started).map(*.key);
                        }
                    }
                }
            }

            my $first-service = Promise.new;
            $first-service.then(
                {
                    sleep 5;
                    my @wait = %services.grep(*.value.state == waiting);
                    if @wait {
                        warn "Some services specified as dependencies did not run in 5 seconds.";
                        say "These are:";
                        say "- {$_.key}" for @wait;
                    };
                }
            );

            whenever $!services.services -> $service {
                $first-service.keep unless $first-service.status ~~ Kept;
                my $path = $service.path;
                my $cro-file = $service.cro-file;
                my $service-id = $cro-file.id;
                if $service-id ~~ $!service-id-filter {
                    my %endpoint-ports = assign-ports($cro-file.endpoints);
                    my ($proc, %env) = service-proc($cro-file, %endpoint-ports);
                    if $cro-file.links.elems == 0 {
                        # No dependencies, just start it
                        enable-service($proc, $service, %endpoint-ports, %env);
                    }
                    else {
                        my @dependencies;
                        for $cro-file.links -> $link {
                            unless (%services{$link.service}) {
                                @dependencies.push: $link.service;
                            }
                        }
                        if @dependencies {
                            %services{$service-id} = ServiceStatus.new(:$proc, :$service,
                                                                       :%endpoint-ports,
                                                                       :%env, state => waiting,
                                                                       :@dependencies);
                        }
                        else {
                            # All dependencies are enabled
                            enable-service($proc, $service, %endpoint-ports, %env);
                        }
                    }
                }
            }

            sub add-service($service, $running-service) {
                %running-services{$service.cro-file.id} = $running-service;
                whenever $service.metadata-changed.merge($service.source-changed).stable(1) {
                    $running-service.cro-file = $service.cro-file;
                    restart-service($running-service);
                }
            }

            sub restart-service($running-service) {
                try $running-service.proc.kill(SIGINT);
                whenever $running-service.proc-exit {
                    given $running-service {
                        (.proc, my %env) = service-proc(.cro-file, .endpoint-ports);
                        .proc-exit = .proc.start(:ENV(%env), :cwd(.path))
                    }
                    emit Restarted.new:
                        service-id => $running-service.cro-file.id,
                        cro-file => $running-service.cro-file;
                }
            }

            CLOSE {
                for %running-services.values {
                    .proc.kill(SIGINT);
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
