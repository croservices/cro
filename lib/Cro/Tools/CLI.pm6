
proto MAIN(|) is export {*}

multi MAIN('web') {
    !!! "web"
}

multi MAIN('stub', Str $service-type, Str $name, Str $path, *@option) {
    !!! "stub"
}

multi MAIN('run') {
    !!! 'run'
}

multi MAIN('run', *@service-name) {
    !!! 'run services'
}

multi MAIN('trace', *@service-name-or-filter) {
    !!! 'trace'
}

multi MAIN('serve', Str $host-port, Str $directory = '.') {
    my ($host, $port);
    given $host-port {
        when /^(\d+)$/ {
            $host = 'localhost';
            $port = +$host-port;
        }
        when /^ (.+) ':' (\d+) $/ {
            $host = ~$0;
            $port = +$1;
        }
        default {
            conk "Don't understand '$host-port'; expected port number of host:port.";
        }
    }
    unless 1 <= $port <= 0xFFFF {
        conk "Port number $port is out of range.";
    }

    if $directory.IO.d {
        use Cro::Tools::Serve;
        my $service = serve $host, $port, $directory;
        say "Serving '$directory' at http://$host:$port/";
        react {
            my $sigints = 0;
            whenever signal(SIGINT) {
                if $sigints++ {
                    done;
                }
                else
                {
                    say "Shutting down server cleanly (Ctrl+C again to force exit).";
                    whenever start $service.stop {
                        done;
                    }
                }
            }
        }
    }
    else {
        conk "The serve command requires a directory, but '$directory' isn't one.";
    }
}

sub conk($message) {
    note $message;
    exit 1;
}
