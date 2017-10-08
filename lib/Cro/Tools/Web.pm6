use Cro::HTTP::Router::WebSocket;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::Tools::Runner;
use Cro::Tools::Template;
use Cro::Tools::TemplateLocator;
use JSON::Fast;

sub web(Str $host, Int $port, $runner) is export {
    my $application = route {
        get -> {
            content 'text/html', %?RESOURCES<web/index.html>.slurp;
        }
        post -> 'service' {
            request-body -> %json {
                unless %json<action> eq 'start'|'restart'|'stop'|'traceFlip' {
                    bad-request;
                }
                $runner.stop(%json<id>) if %json<action> eq 'stop';
                $runner.start(%json<id>) if %json<action> eq 'start';
                $runner.restart(%json<id>) if %json<action> eq 'restart';
                $runner.traceFlip(%json<id>) if %json<action> eq 'traceFlip';
                content 'text/html', '';
            }
        }
        post -> 'stub' {
            request-body -> %json {
                # TODO - stubbing
                content 'text/html', '';
            }
        }
        get -> 'stub-road' {
            web-socket -> $incoming {
                my @templates = get-available-templates(Cro::Tools::Template);
                supply {
                    my @result = ();
                    for @templates -> $_ {
                        my %result;
                        %result<id> = .id;
                        %result<name> = .name;
                        my @options;
                        @options.push((.id, .name,
                                       .type.^name,
                                       # We don't send blocks (yet?)
                                       .default ~~ Bool ?? .default !! False).List) for .options;
                        %result<options> = @options;
                        @result.push(%result);
                    }
                    emit to-json {
                        WS_ACTION => True,
                        action => {
                            type => 'STUB_TEMPLATES',
                            templates => @result
                        }
                    };
                }
            }
        }
        get -> 'services-road' {
            web-socket -> $incoming {
                supply whenever $runner.run() -> $_ {
                    when Cro::Tools::Runner::Started {
                        my %action = type => 'SERVICE_STARTED',
                                     id   => .cro-file.id,
                                     name => .cro-file.name;
                        emit to-json {
                            WS_ACTION => True,
                            :%action
                        }
                    }
                    when Cro::Tools::Runner::Restarted {
                        my %action = type => 'SERVICE_RESTARTED',
                                     id   => .cro-file.id,
                                     name => .cro-file.name;
                        emit to-json {
                            WS_ACTION => True,
                            :%action
                        }
                    }
                    when Cro::Tools::Runner::Output {
                    }
                    when Cro::Tools::Runner::Trace {
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
