use Cro::Tools::CroFile;
use File::Find;

sub add($from-service, $to-service, $to-endpoint?) {
    my @ymls = find(dir => '.', name => / \.yml$/);
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
    die "Service with 'from-service' id is not found!" unless $from;
    die "Service with 'to-service' id is not found!" unless $to;

    with $to-endpoint {
        for $to.endpoints {
            if .id eq $to-endpoint {
                $endpoint = $_;
                last;
            }
        }
        unless $endpoint {
            die "Endpoint $to-endpoint was specified, but there is no such endpoint for $from-service service!"
        }
    }
    else {
        die 'No endpoint is specified, link is ambiguous!' unless $to.endpoints.elems == 1
    }

    my $link = Cro::Tools::CroFile::Link.new:
        service  => $to.id,
        endpoint => $endpoint.id,
        host-env => $endpoint.host-env,
        port-env => $endpoint.port-env;
    $from.links.push($link);
    spurt $path, $from.to-yaml;
}
