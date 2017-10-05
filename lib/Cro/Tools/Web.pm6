use Cro::HTTP::Router::WebSocket;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::Tools::Runner;
use JSON::Fast;

sub web(Str $host, Int $port, $runner) is export {
    my $application = route {
        get -> {
            content 'text/html', %?RESOURCES<web/index.html>.slurp;
        }
        get -> 'services-road' {
            web-socket -> $incoming {
                supply whenever $runner.run() -> $_ {
                    when Cro::Tools::Runner::Started {
                        note "Service {.cro-file.name} is started!";
                        my %action = type => 'SERVICE_STARTED',
                                     name => .cro-file.name;
                        emit to-json {
                            WS_ACTION => True,
                            :%action
                        }
                    }
                }
            }
        }
        get -> 'css', *@path {
            with %?RESOURCES{('web', 'css', |@path).join('/')} {
                content 'text/css', .slurp;
            }
            else {
                not-found;
            }
        }
        get -> 'js', *@path {
            with %?RESOURCES{('web', 'js', |@path).join('/')} {
                content 'text/javascript', .slurp;
            }
            else {
                not-found;
            }
        }
    }
    given Cro::HTTP::Server.new(:$host, :$port, :$application) {
        .start;
        .return;
    }
}
