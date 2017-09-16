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

    method run(--> Supply) {
        supply {
            my class RunningService {
                has $.path;
                has %.endpoint-ports;
                has $.proc is rw;
                has $.proc-exit is rw;
                has $.cro-file is rw;
            }
            my %running-services;

            whenever $!services.services -> $service {
                my $path = $service.path;
                my $cro-file = $service.cro-file;
                my $service-id = $cro-file.id;
                if $service-id ~~ $!service-id-filter {
                    my %endpoint-ports = assign-ports($cro-file.endpoints);
                    my ($proc, $proc-exit) = service-proc($path, $cro-file, %endpoint-ports);
                    whenever $proc.ready {
                        add-service $service, RunningService.new:
                            :$path, :%endpoint-ports, :$proc, :$proc-exit, :$cro-file;
                        emit Started.new(:$service-id, :$cro-file, :%endpoint-ports);
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
                        (.proc, .proc-exit) = service-proc(.path, .cro-file, .endpoint-ports);
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

            sub service-proc($path, $cro-file, %endpoint-ports) {
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
                return $proc, $proc.start(:ENV(%env), :cwd($path));
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
