use Cro::HTTP::Router::WebSocket;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::Tools::Runner;
use Cro::Tools::Template;
use Cro::Tools::TemplateLocator;
use JSON::Fast;

sub web(Str $host, Int $port, $runner) is export {
    my $stub-events = Supplier.new;
    my $application = route {
        get -> {
            content 'text/html', %?RESOURCES<web/index.html>.slurp;
        }
        post -> 'service' {
            request-body -> %json {
                my @commands = <start restart stop
                              trace-on trace-off
                              trace-all-on trace-all-off>;
                unless %json<action> ⊆ @commands {
                    bad-request;
                }
                $runner.start(%json<id>)        if %json<action> eq 'start';
                $runner.stop(%json<id>)         if %json<action> eq 'stop';
                $runner.restart(%json<id>)      if %json<action> eq 'restart';
                $runner.trace(%json<id>, 'on')  if %json<action> eq 'trace-on';
                $runner.trace(%json<id>, 'off') if %json<action> eq 'trace-off';
                $runner.trace-all('on')         if %json<action> eq 'trace-all-on';
                $runner.trace-all('off')        if %json<action> eq 'trace-all-off';
                content 'text/html', '';
            }
        }
        post -> 'stub' {
            request-body -> %json {
                my @templates = get-available-templates(Cro::Tools::Template);
                my $found = @templates.first(*.id eq %json<type>);
                my %options = %json<options>>>.Hash;
                my $generated-links;
                if $found.get-option-errors(%options) -> @errors {
                    $stub-events.emit: {
                        WS_ACTION => True,
                        action => { type => 'STUB_OPTIONS_ERROR_OCCURED',
                                    errors => @errors }
                    }
                }
                else {
                    try {
                        my $where = $*CWD.add(%json<id>);
                        mkdir $where;
                        $found.generate($where, %json<id>, %json<id>, %options, $generated-links);
                        $stub-events.emit: {
                            WS_ACTION => True,
                            action => { type => 'STUB_STUBBED' }
                        }
                    }
                    CATCH {
                        default {
                            $stub-events.emit: {
                                WS_ACTION => True,
                                action => { type => 'STUB_',
                                            errors => $_ }
                            }
                        }
                    }
                }
                content 'text/html', '';
            }
        }
        get -> 'stub-road' {
            web-socket -> $incoming {
                my @templates = get-available-templates(Cro::Tools::Template);
                supply {
                    whenever $stub-events.Supply {
                        emit to-json $_;
                        CATCH {.note}
                    }
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
                    sub emit-action($_, $type) {
                        my %action = :$type, id => .cro-file.id,
                                     name => .cro-file.name,
                                     tracing => .tracing;
                        emit to-json { WS_ACTION => True, :%action }
                    }

                    when Cro::Tools::Runner::Started {
                        emit-action($_, 'SERVICE_STARTED');
                    }
                    when Cro::Tools::Runner::Restarted {
                        emit-action($_, 'SERVICE_RESTARTED')
                    }
                    when Cro::Tools::Runner::Stopped {
                        emit-action($_, 'SERVICE_STOPPED')
                    }
                    when Cro::Tools::Runner::UnableToStart {
                        emit-action($_, 'SERVICE_UNABLE_TO_START')
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
