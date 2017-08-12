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

    has Cro::Tools::Services $.services is required;
    has $.service-id-filter = *;

    method run(--> Supply) {
        supply {
            my $next-try-port = 20000;

            whenever $!services.services {
                my $path = .path;
                my $cro-file = .cro-file;
                my $service-id = $cro-file.id;
                if $service-id ~~ $!service-id-filter {
                    my %endpoint-ports = assign-ports($cro-file.endpoints);
                    my ($proc, $proc-exit) = service-proc($path, $cro-file, %endpoint-ports);
                    whenever $proc.ready {
                        emit Started.new(:$service-id, :$cro-file, :%endpoint-ports);
                    }
                }
            }

            sub assign-ports(@endpoints) {
                hash @endpoints.map({ .id => free-port() })
            }

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
                        return $next-try-port;
                    }
                }    
            }

            sub service-proc($path, $cro-file, %endpoint-ports) {
                my %env = %*ENV;
                for $cro-file.endpoints -> $endpoint {
                    with $endpoint.host-env {
                        %env{$_} = 'localhost';
                    }
                    with $endpoint.port-env {
                        %env{$_} = %endpoint-ports{$endpoint.id};
                    }
                }
                my $proc = Proc::Async.new('perl6', '-Ilib', $cro-file.entrypoint);
                return $proc, $proc.start(:ENV(%env), :cwd($path));
            }
        }
    }
}
