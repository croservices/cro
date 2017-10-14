use Cro::Tools::CroFile;
use File::Find;

my sub check-services($from-service, $to-service, $to-endpoint?) {
    my @ymls = find(dir => $*CWD, name => / \.cro\.yml$/);
    my ($path, $from, $to, $endpoint);
    for @ymls -> $p {
        my $cro-file = Cro::Tools::CroFile.parse($p.IO.slurp);
        given $cro-file.id {
            when $from-service {
                $from = $cro-file;
                $path = $p.IO;
            }
            when $to-service {
                $to = $cro-file;
            }
        }
        last if $from && $to;
    }

    # Query sanity checks
    die "Service with '$from-service' id is not found!" unless $from;
    die "Service with '$to-service' id is not found!" unless $to;

    with $to-endpoint {
        for $to.endpoints {
            if .id eq $to-endpoint {
                $endpoint = $_;
                last;
            }
        }
        unless $endpoint {
            die "Endpoint $to-endpoint was specified, but there is no such endpoint for $from-service."
        }
    }
    else {
        if $to.endpoints.elems == 1 {
            $endpoint = $to.endpoints[0];
        }
        else {
            die 'No endpoint is specified, link is ambiguous.';
        }
    }
    ($path, $from, $to, $endpoint);
}

our sub add-link($from-service, $to-service, $to-endpoint?) {
    my ($path, $from, $to, $endpoint) = check-services($from-service,
                                                       $to-service,
                                                       $to-endpoint);

    my $link = Cro::Tools::CroFile::Link.new:
        service  => $to.id,
        endpoint => $endpoint.id,
        host-env => $endpoint.host-env,
        port-env => $endpoint.port-env;
    for $from.links {
        if $_ eqv $link {
            note "Link from $from-service to $to-service already exists.";
            return;
        }
    }
    $from.links.push($link);
    spurt $path, $from.to-yaml;
    print-endpoint($to-service, $endpoint);
}

our sub rm-link($from-service, $to-service, $to-endpoint?) {
    my ($path, $from, $to, $endpoint) = check-services($from-service,
                                                       $to-service,
                                                       $to-endpoint);
    my $links = $from.links.elems;
    $from.links .= grep({ $endpoint
                          ?? not (.service eq $to-service && .endpoint eq $endpoint.id)
                          !! not  .service eq $to-service
                        });
    if $links != $from.links.elems {
        spurt $path, $from.to-yaml;
    } else {
        die 'Such link does not exist. Did you mean `add`?';
    }
}

my sub print-endpoint($to-service, $ep) {
    use Cro::Tools::TemplateLocator;
    use Cro::Tools::LinkTemplate;
    my @templates = get-available-templates(Cro::Tools::LinkTemplate);
    for @templates {
        if $ep.protocol eq $_.protocol {
            my $g-link = $_.generate($to-service, $ep.id,
                                    (host-env => $ep.host-env,
                                     port-env => $ep.port-env));
            say "use $_;" for $g-link.use;
            say "\n" ~ $g-link.setup-code;
            last;
        }
    }
}

our sub code-link($from-service, $to-service, $to-endpoint?) {
    my ($path, $from, $to, $ep) = check-services($from-service,
                                                       $to-service,
                                                       $to-endpoint);
    print-endpoint($to-service, $ep);
}

our sub links-graph($service?) {
    my @ymls = find(dir => $*CWD, name => / \.cro\.yml$/);
    # @inner - possibly includes service to get links 'from';
    # @outer - includes all other services to process
    my (@inner, @outer);
    for @ymls {
        my $cro-file = Cro::Tools::CroFile.parse(.IO.slurp);
        # $service can be undefined here, so provide an impossible backup value
        if $cro-file.id eq ($service // '') {
            ($service ?? @inner !! @outer).append: $cro-file;
        } else {
            @outer.append: $cro-file;
        }
    }
    if $service && !@inner {
        die "No such service $service";
    }
    {:@inner, :@outer};
}

our sub show-link($service?) {
    my %services = links-graph($service);
    my @inner = %services<inner>.flat;
    my @outer = %services<outer>.flat;
    with $service {
        say "Links from $service:";
        for @inner[0].links {
            say " - to ｢{.service}｣-｢{.endpoint}｣ by ｢{.host-env}:{.port-env}｣"
        }
        say "Links to $service:";
        for @outer -> $cro-file { # All other services
            for $cro-file.links.grep({ .service eq $service }) {
                say " - from ｢{$cro-file.id}｣ to ｢{.endpoint}｣ by ｢{.host-env}:{.port-env}｣"
            }
        }
    }
    without $service {
        for @outer {
            say "Links from {$_.id}:";
            for .links {
                say " - to ｢{.service}｣-｢{.endpoint}｣ by ｢{.host-env}:{.port-env}｣";
            }
        }
    }
}
