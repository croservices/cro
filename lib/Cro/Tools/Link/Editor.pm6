use Cro::Tools::CroFile;
use File::Find;

my sub check-services($from-service, $to-service, $to-endpoint?) {
    my @ymls = find(dir => '.', name => / \.cro\.yml$/);
    my ($path, $from, $to, $endpoint);
    for @ymls {
        my $cro-file = Cro::Tools::CroFile.parse($_.IO.slurp);
        given $cro-file.id {
            when $from-service {
                $from = $cro-file;
                $path = $_.IO;
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

sub add($from-service, $to-service, $to-endpoint?) {
    my ($path, $from, $to, $endpoint) = check-services($from-service,
                                                       $to-service,
                                                       $to-endpoint);

    my $link = Cro::Tools::CroFile::Link.new:
        service  => $to.id,
        endpoint => $endpoint.id,
        host-env => $endpoint.host-env,
        port-env => $endpoint.port-env;
    $from.links.push($link);
    spurt $path.add('.cro.yml'), $from.to-yaml;
}

sub rm($from-service, $to-service, $to-endpoint?) {
    my ($path, $from, $to, $endpoint) = check-services($from-service,
                                                       $to-service,
                                                       $to-endpoint);
    my $links = $from.links.elems;
    $from.links .= grep({ $endpoint
                          ?? not (.service eq $to-service && .endpoint eq $endpoint.id)
                          !! not  .service eq $to-service
                        });
    if $links != $from.links.elems {
        spurt $path.add('.cro.yml'), $from.to-yaml;
    } else {
        die 'Such link does not exist. Did you mean `add`?';
    }
}
