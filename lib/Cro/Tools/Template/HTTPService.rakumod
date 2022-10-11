use Cro::Tools::CroFile;
use Cro::Tools::Template;
use Cro::Tools::Template::Common;

class Cro::Tools::Template::HTTPService does Cro::Tools::Template does Cro::Tools::Template::Common {
    method id(--> Str) { 'http' }

    method name(--> Str) { 'HTTP Service' }

    method options(--> List) {
        Option.new(
            id => 'http1',
            name => 'Support HTTP/1.1',
            type => Bool,
            default => True
        ),
        Option.new(
            id => 'http2',
            name => 'Support HTTP/2.0',
            type => Bool,
            default => { !.<http1> }
        ),
        Option.new(
            id => 'secure',
            name => 'Secure (HTTPS)',
            type => Bool,
            default => { .<http2> },
            skip-condition => { .<http2> }
        ),
        Option.new(
            id => 'websocket',
            name => 'Support Web Sockets',
            type => Bool,
            default => False
        )
    }

    method get-option-errors((:$http1, :$http2, :$secure, *%) --> List) {
        my @errors;
        unless $http1 || $http2 {
            push @errors, 'Must select at least one of HTTP/1.1 or HTTP/2.0';
        }
        if $http1 && $http2 && !$secure {
            push @errors, 'Can only support HTTP/1.1 and HTTP/2.0 with HTTPS';
        }
        return @errors;
    }

    method generate(IO::Path $where, Str $id, Str $name,
                    %options, $generated-links, @links) {
        my %dir = self.make-directories($where);
        self.write-fake-tls($where) if %options<secure>;
        self.write-app-module(%dir<lib>.add('Routes.rakumod'), $name, %options, $generated-links);
        self.generate-common($where, $id, $name, %options, $generated-links, @links);
    }

    method new-directories($where) {
        lib => $where.add('lib'),
    }

    method write-fake-tls($where) {
        my $res = $where.add('resources/');
        mkdir $res;
        mkdir $res.add('fake-tls');
        for <fake-tls/ca-crt.pem fake-tls/server-crt.pem fake-tls/server-key.pem> -> $fn {
            with %?RESOURCES{$fn} {
                copy($_, $res.add($fn));
            }
        }
    }

    method app-module-contents($name, %options, $links) {
        my $include-websocket = %options<websocket>;
        my $module = "use Cro::HTTP::Router;\n";
        $module ~= "use Cro::HTTP::Router::WebSocket;\n" if $include-websocket;

        my $args = $links ?? ':' ~ $links.map({ .setup-variable }).join(', :') !! '';
        my $static = self.static-routes($name, $include-websocket, $links);
        my $websocket = $include-websocket ?? self.websocket-routes($name, $links) !! '';
        $module ~= q:s:to/CODE/;

            sub routes($args) is export {
                route {
            $static$websocket    }
            }
            CODE

        $module
    }

    method static-routes($name, $include-websocket, $links) {
        q:s:to/CODE/;
                    get -> {
                        content 'text/html', "<h1> $name </h1>";
                    }
            CODE
    }

    method websocket-routes($name, $links) {
        q:to/CODE/;

                    my $chat = Supplier.new;
                    get -> 'chat' {
                        web-socket -> $incoming {
                            supply {
                                whenever $incoming -> $message {
                                    $chat.emit(await $message.body-text);
                                }
                                whenever $chat -> $text {
                                    emit $text;
                                }
                            }
                        }
                    }
            CODE
    }

    method write-app-module($file, $name, $include-websocket, $links) {
        $file.spurt(self.app-module-contents($name, $include-websocket, $links));
    }

    method entrypoint-contents($id, %options, $links) {
        my $env-name = self.env-name($id);
        my $http = %options<http1> && %options<http2>
            ?? <1.1 2>
            !! %options<http1> ?? <1.1> !! <2>;
        my $entrypoint = q:c:to/CODE/;
        use Cro::HTTP::Log::File;
        use Cro::HTTP::Server;
        use Routes;
        CODE
        $entrypoint ~= $links ?? ("use {$_};\n" for @$links.map(*.use).flat.unique) !! '';
        $entrypoint ~= "\n";
        if $links {
            $entrypoint ~= .setup-code ~ "\n" for @$links;
        }

        $entrypoint ~= q:c:to/CODE/;
            my Cro::Service $http = Cro::HTTP::Server.new(
                http => <{$http}>,
                host => %*ENV<{$env-name}_HOST> ||
                    die("Missing {$env-name}_HOST in environment"),
                port => %*ENV<{$env-name}_PORT> ||
                    die("Missing {$env-name}_PORT in environment"),
            CODE

        if %options<secure> {
            $entrypoint ~= q:c:to/CODE/;
                    tls => %(
                        private-key-file => %*ENV<{$env-name}_TLS_KEY> ||
                CODE
            $entrypoint ~= Q:to/CODE/;
                            %?RESOURCES<fake-tls/server-key.pem> || "resources/fake-tls/server-key.pem",
                CODE
            $entrypoint ~= q:c:to/CODE/;
                        certificate-file => %*ENV<{$env-name}_TLS_CERT> ||
                CODE
            $entrypoint ~= Q:to/CODE/;
                            %?RESOURCES<fake-tls/server-crt.pem> || "resources/fake-tls/server-crt.pem",
                    ),
                CODE
        }

        my $vars-list = $links ?? ':' ~ $links.map({ .setup-variable }).join(', :') !! '';
        my $routes = 'routes(' ~ ($vars-list) ~ ')';
        $entrypoint ~= q:c:to/CODE/;
                application => {$routes},
                after => [
                    Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
                ]
            );
            $http.start;
            say "Listening at http{%options<secure> ?? 's' !! ''}://%*ENV<{$env-name}_HOST>:%*ENV<{$env-name}_PORT>";
            CODE
        $entrypoint ~= q:to/CODE/;
            react {
                whenever signal(SIGINT) {
                    say "Shutting down...";
                    $http.stop;
                    done;
                }
            }
            CODE

        $entrypoint
    }

    method cro-file-endpoints($id-uc, %options) {
        Cro::Tools::CroFile::Endpoint.new(
            id => %options<secure> ?? 'https' !! <http>,
            name => %options<secure> ?? 'HTTPS' !! 'HTTP',
            protocol => %options<secure> ?? 'https' !! 'http',
            host-env => $id-uc ~ '_HOST',
            port-env => $id-uc ~ '_PORT'
        ),
    }

    method meta6-depends(%options) {
         <Cro::HTTP>,
        (<Cro::WebSocket> if %options<websocket>)
    }

    method meta6-resources(%options) {
        %options<secure> ?? <fake-tls/ca-crt.pem
                             fake-tls/server-crt.pem
                             fake-tls/server-key.pem> !! ()
    }

    method meta6-provides(%options) {
        'Routes' => 'lib/Routes.rakumod',
    }

    method docker-base-image(%options) {
        %options<websocket> ?? 'croservices/cro-http-websocket' !! 'croservices/cro-http'
    }
}
