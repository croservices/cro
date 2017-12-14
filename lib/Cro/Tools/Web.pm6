use Cro::HTTP::Router::WebSocket;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::Tools::Link::Editor;
use Cro::Tools::LinkTemplate;
use Cro::Tools::Runner;
use Cro::Tools::Template;
use Cro::Tools::TemplateLocator;
use JSON::Fast;

sub web(Str $host, Int $port, $runner) is export {
    my $stub-events = Supplier::Preserving.new;
    my $logs-events = Supplier::Preserving.new;
    my $overview-events = Supplier::Preserving.new;
    my $link-events = Supplier::Preserving.new;

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
            when 'overview' {
                $overview-events.emit: $msg;
            }
            when 'link' {
                $link-events.emit: $msg;
            }
        }
    }

    sub handle-error($path, $type, $e) {
        # Print error to terminal too to easify bug reporting
        $e.note;
        my $errorMsg = "$e {$e.backtrace.full}";
        send-event($path, { :$type , :$errorMsg })
    }

    my $application = route {
        get -> {
            content 'text/html', %?RESOURCES<web/index.html>.slurp;
        }
        get -> $app-route {
            content 'text/html', %?RESOURCES<web/index.html>.slurp;
        }
        get -> 'links', $service-id {
            content 'text/html', %?RESOURCES<web/index.html>.slurp;
        }
        post -> 'service' {
            request-body -> %json {
                my @commands = <start restart stop
                              trace-on trace-off
                              trace-all-on trace-all-off>;
                bad-request unless %json<action> ⊆ @commands;
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
                    my (@generated-links, @links);
                    populate-links(
                        %json<links>.map(
                            {
                                "{$_<service>}:{$_<endpoint>}";
                            }
                        ),
                        @generated-links, @links
                    );
                    if $found.get-option-errors(%options) -> @errors {
                        my $errors = @errors.map({ "$_\n" }).join;
                        send-event('stub', { type => 'STUB_OPTIONS_ERROR_OCCURED',
                                             :$errors });
                    }
                    else {
                        my $where = $*CWD.add(%json<path>);
                        mkdir $where;
                        $found.generate($where, %json<id>, %json<name>, %options, @generated-links, @links);
                        send-event('stub', { type => 'STUB_STUBBED' });
                        # Update graph
                        my $color = 10.rand.Int;
                        my %graph-event = type => 'OVERVIEW_ADD_NODE',
                                          node => { id => %json<id>,
                                                    type => $color
                                                  },
                                          links => @links.map(
                                              { my %link;
                                                %link<source> = %json<name>;
                                                %link<target> = .service;
                                                %link<type> = $color;
                                                %link }
                                          );
                        send-event('overview', %graph-event);
                        CATCH {
                            default {
                                handle-error('stub', 'STUB_STUB_ERROR_OCCURED', $_);
                            }
                        }
                    }
                }
            }
        }
        post -> 'link' {
            request-body -> %json {
                my @actions = <LINK_CREATE_LINK LINK_REMOVE_LINK>;
                bad-request unless %json<type> ⊆ @actions;
                content 'text/html', '';
                start {
                    if (%json<type> eq 'LINK_CREATE_LINK') {
                        add-link(%json<id>, %json<service>, %json<endpoint>);
                        my $code = code-link(%json<id>, %json<service>, %json<endpoint>);
                        send-event('link', { type => 'LINK_CODE',
                                             id => %json<id>,
                                             service => %json<service>,
                                             endpoint => %json<endpoint>,
                                             :$code });
                    } elsif (%json<type> eq 'LINK_REMOVE_LINK') {
                        rm-link(%json<id>, %json<service>, %json<endpoint>);
                    }
                    CATCH {
                        default {
                            handle-error('link', 'LINK_ERROR', $_);
                        }
                    }
                }
            }
        }

        get -> 'overview-road' {
            web-socket -> $incoming {
                supply {
                    whenever $overview-events.Supply {
                        emit to-json $_;
                    }

                    my (@nodes, @links);
                    my @services = links-graph()<outer>.flat;
                    for @services.kv -> $color, $cro-file {
                        @nodes.push: { id => $cro-file.id, type => $color };
                        for $cro-file.links {
                            my $source = $cro-file.id;
                            my $target = .service;
                            if @services.grep(*.id eq $target) {
                                @links.push: { :$source, :$target, type => $color };
                            }
                        }
                    }
                    my %graph = :@nodes, :@links;
                    send-event('overview', { type => 'OVERVIEW_GRAPH', :%graph });
                }
            }
        }
        get -> 'link-road' {
            web-socket -> $incoming {
                supply {
                    for links-graph()<outer>.flat -> $s {
                        my %json = type => 'LINK_ADD_LINK', id => $s.id;
                        # XXX: Golfing is welcome
                        my @links;
                        for $s.links {
                            my %hash = service  => .service,
                                       endpoint => .endpoint,
                                       code => code-link($s.id, .service, .endpoint);
                            @links.push: %hash;
                        }
                        %json<links> = @links;
                        %json<endpoints> = $s.endpoints.map(*.id);
                        send-event('link', %json);
                    }
                    whenever $link-events.Supply {
                        emit to-json $_;
                    }
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
                                     name => $c.name;
                        %action<tracing> = .tracing if $_ !~~ Cro::Tools::Runner::UnableToStart;
                        %action<endpoints> = @endpoints if $_ ~~ Cro::Tools::Runner::Started;
                        emit to-json { WS_ACTION => True, :%action }
                    }

                    when Cro::Tools::Runner::Started {
                        my %event;
                        emit-action($_, 'SERVICE_STARTED');
                        %event = type => 'LOGS_NEW_CHANNEL', id => .cro-file.id;
                        send-event('logs', %event);
                        %event = type => 'STUB_NEW_LINK', id => .cro-file.id, endpoints => .cro-file.endpoints.map(*.id);
                        send-event('stub', %event);
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
