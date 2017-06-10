# Cro::HTTP::Server

The `Cro::HTTP::Server` class is the most convenient way to host a HTTP or
HTTPS service in Cro. Instances of `Cro::HTTP::Server` do the `Cro::Service`
role, and as such have the `start` and `stop` methods. The only required
configuration for a `Cro::HTTP::Server` is an **application**, which is any
`Cro::Transform` that consumes a `Cro::HTTP::Request` and produces a
`Cro::HTTP::Response`. This will often be produced using `Cro::HTTP::Router`.

## A minimal setup

The following example demonstrates how `Cro::HTTP::Server` can be used to host
a simple "Hello, world" HTTP application, configuring it to listen on port 8888
of localhost. A signal handler is added to allow for clean shutdown of the
server upon Ctrl + C.

    use Cro::HTTP::Router;
    use Cro::HTTP::Server;

    my $application = route {
        get -> {
            content 'text/html', '<strong>Hello, world!</strong>';
        }
    }

    my Cro::Service $hello-service = Cro::HTTP::Server.new(
        :host('localhost'), :port(8888), :$application
    );
    $hello-service.start;
    react whenever signal(SIGINT) {
        $hello-service.stop;
        exit;
    }

## Configuring HTTPS

By default, `Cro::HTTP::Server` will operates as a HTTP server. To set it up
as a HTTPS server instead, use the `ssl` named parameter. It expects to receive
a hash of arguments providing the SSL configuration, which it will in turn pass
to the constructor of `Cro::TLS::Listener`. Typically, `certificate-file` and
`private-key-file`, specifying the locations of files containing a certificate
and private key respectively, should be passed.

    my %ssl = private-key-file => 'server.pem',
              certificate-file => 'cert.pem';
    my Cro::Service $hello-service = Cro::HTTP::Server.new(
        :host('localhost'), :port(8888), :%ssl, :$application
    );

## Request body parsers and response body serializers

Additional request body parsers (implementations of `Cro::HTTP::BodyParser`)
and response body serializers (impelemntations of `Cro::HTTP::BodySerializer`)
can be added at the server level. Alternatively, the set of default set of
body parsers and serializers can be replaced entirely.

To add extra body parsers to the set of defaults, pass a list of them to
`add-body-parsers`.

    my Cro::Service $hello-service = Cro::HTTP::Server.new(
        :host('localhost'), :port(8888), :$application,
        add-body-parsers => [
            YAMLBodyParser,
            XMLBodyParser
        ]
    );

These will take precedence over (that is, tested for applicability ahead of)
the default set of body parsers. To replace those entirely, pass a list of the
body parsers to use as the `body-parsers` named parameter:

    my Cro::Service $hello-service = Cro::HTTP::Server.new(
        :host('localhost'), :port(8888), :$application,
        body-parsers => [
            # Don't parse any kind of body except a JSON one; anything else
            # will throw an exception when `.body` is called.
            Cro::HTTP::BodyParser::JSON
        ]
    );

If both `body-parsers` and `add-body-parsers` is used, then both will be used,
with those in `add-body-parsers` again having higher precedence.

A similar scheme applies for body serializers. Use `add-body-serializers` to
add extra ones to the defaults:

    my Cro::Service $hello-service = Cro::HTTP::Server.new(
        :host('localhost'), :port(8888), :$application,
        add-body-serializers => [
            YAMLBodySerializer,
            XMLBodySerializer
        ]
    );

Or replace the set of body serializers entirely by passing `body-serializers`:

    my Cro::Service $hello-service = Cro::HTTP::Server.new(
        :host('localhost'), :port(8888), :$application,
        body-serializers => [
            # The body can only ever be something that can be JSON serialized.
            Cro::HTTP::BodySerializer::JSON
        ]
    );

If both `add-body-serializers` and `body-serializers` are passed, they both
will be used, with those in `add-body-serializers` taking precedence.

## HTTP versions

The `:http` option can be passed to control which versions of HTTP should be
supported. It can be passed a single item or list. Valid options are `1.1`
(which will implicitly handle HTTP/1.0 too) and `2`.

    :http<1.1>      # HTTP/1.1 only
    :http<2>        # HTTP/2 only
    :http<1.1 2>    # HTTP/1.1 and HTTP/2 (SSL only; selected by ALPN)

The default is `:http<1.1>` for a HTTP server, and `:http<1.1 2>` for a HTTPS
server. The only supported mechanism for selecting between HTTP/1.1 and HTTP/2
is Application Level Protocol Negotiation, which is part of SSL. Therefore, it
is not possible to have a HTTP server that can accept both HTTP/1.1 and HTTP/2
connections in Cro.
