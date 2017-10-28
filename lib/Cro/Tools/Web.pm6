use Cro::HTTP::Router::WebSocket;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::Tools::Link::Editor;
use Cro::Tools::Runner;
use Cro::Tools::Template;
use Cro::Tools::TemplateLocator;
use JSON::Fast;

sub web(Str $host, Int $port, $runner) is export {
    my $stub-events = Supplier.new;
    my $logs-events = Supplier.new;
    sub send-event($channel, %content) {
        my $msg = { WS_ACTION => True,
                    action => %content };
        given $channel {
            when 'stub' {
                $stub-events.emit: $msg;
            }
            when 'logs' {
                $logs-events.emit: $msg;
            }
        }
    }

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
                content 'text/html', '';
                start {
                    $runner.start(%json<id>)        if %json<action> eq 'start';
                    $runner.stop(%json<id>)         if %json<action> eq 'stop';
                    $runner.restart(%json<id>)      if %json<action> eq 'restart';
                    $runner.trace(%json<id>, 'on')  if %json<action> eq 'trace-on';
                    $runner.trace(%json<id>, 'off') if %json<action> eq 'trace-off';
                    $runner.trace-all('on')         if %json<action> eq 'trace-all-on';
                    $runner.trace-all('off')        if %json<action> eq 'trace-all-off';
                }
            }
        }
        post -> 'stub' {
            request-body -> %json {
                content 'text/html', '';
                start {
                    my @templates = get-available-templates(Cro::Tools::Template);
                    my $found = @templates.first(*.id eq %json<type>);
                    my %options = %json<options>>>.Hash;
                    my ($generated-links, @links);
                    if $found.get-option-errors(%options) -> @errors {
                        send-event('stub', { type => 'STUB_OPTIONS_ERROR_OCCURED',
                                             errors => @errors });
                    }
                    else {
                        my $where = $*CWD.add(%json<path>);
                        mkdir $where;
                        $found.generate($where, %json<id>, %json<name>, %options, $generated-links, @links);
                        send-event('stub', { type => 'STUB_STUBBED' });
                        CATCH {
                            default {
                                my @errors = .backtrace.full.split("\n");
                                send-event('stub', { type => 'STUB_STUB_ERROR_OCCURED',
                                                     :@errors });
                            }
                        }
                    }
                }
            }
        }
        get -> 'overview-road' {
            web-socket -> $incoming {
                supply {
                    my $color = 1;
                    my @nodes;
                    my @links;
                    my %graph;
                    my %services = links-graph();
                    for %services<outer>.flat -> $cro-file {
                        @nodes.push: { id => $cro-file.id, type => $color  };
                        for $cro-file.links {
                            my $source = $cro-file.id;
                            my $target = .service;
                            @links.push: { :$source, :$target, type => $color }
                        }
                        $color++;
                    }
                    %graph<nodes> = @nodes;
                    %graph<links> = @links;
                    emit to-json {
                        WS_ACTION => True,
                        action => {
                            type => 'OVERVIEW_GRAPH',
                            :%graph
                        }
                    };
                }
            }
        }
        get -> 'logs-road' {
            web-socket -> $incoming {
                supply {
                    whenever $logs-events.Supply {
                        emit to-json $_;
                    }
                }
            }
        }
        get -> 'stub-road' {
            web-socket -> $incoming {
                my @templates = get-available-templates(Cro::Tools::Template);
                supply {
                    whenever $stub-events.Supply {
                        emit to-json $_;
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
                    emit to-json {
                        WS_ACTION => True,
                        action => {
                            type => 'STUB_SET_PATH',
                            path => ~$*CWD
                        }
                    }
                }
            }
        }
        get -> 'services-road' {
            web-socket -> $incoming {
                supply whenever $runner.run() -> $_ {
                    sub emit-action($_, $type) {
                        my $c = .cro-file;
                        my @endpoints;
                        if $_ ~~ Cro::Tools::Runner::Started {
                            @endpoints = .endpoint-ports.map(
                                -> $e {[$e.key, $e.value,
                                        $c.endpoints.grep({ .id eq $e.key }).first.protocol] });
                        }
                        my %action = :$type, id => $c.id,
                                     name => $c.name,
                                     tracing => .tracing;
                        %action<endpoints> = @endpoints if $_ ~~ Cro::Tools::Runner::Started;
                        emit to-json { WS_ACTION => True, :%action }
                    }

                    when Cro::Tools::Runner::Started {
                        emit-action($_, 'SERVICE_STARTED');
                        my %event = type => 'LOGS_NEW_CHANNEL', id => .cro-file.id;
                        send-event('logs', %event);
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
                        my $payload = .line;
                        if .on-stderr {
                            $payload = "\c[WARNING SIGN] " ~ $payload;
                        } else {
                            $payload = "\c[NOTEBOOK] " ~ $payload;
                        }
                        my %event = type => 'LOGS_UPDATE_CHANNEL',
                                    id => .service-id, :$payload;
                        send-event('logs', %event);
                    }
                    when Cro::Tools::Runner::Trace {
                        my $payload;
                        $payload = do given .event {
                            when 'EMIT' { "\c[HIGH VOLTAGE SIGN] EMIT " }
                            when 'DONE' { "\c[BLACK SQUARE FOR STOP] DONE " }
                            when 'QUIT' { "\c[SKULL AND CROSSBONES] QUIT " }
                            default { "? {.uc}" }
                        }
                        $payload ~= "[{.id}] {.component}\n";
                        $payload ~= .data.indent(2);
                        my %event = type => 'LOGS_UPDATE_CHANNEL',
                                    id => .service-id, :$payload;
                        send-event('logs', %event);
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
        get -> 'fonts', *@path {
            with %?RESOURCES{('web', 'fonts', |@path).join('/')} {
                content 'font/woff2', .slurp :bin;
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
