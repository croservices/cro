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

```
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
```

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
and response body serializers (implementations of `Cro::HTTP::BodySerializer`)
can be added at the server level. Alternatively, the set of default set of
body parsers and serializers can be replaced entirely.

To add extra body parsers to the set of defaults, pass a list of them to
`add-body-parsers`.

    my Cro::Service $hello-service = Cro::HTTP::Server.new(
        :host('localhost'), :port(8888), :$application,
        add-body-parsers => [
            YAMLBodyParser.new,
            XMLBodyParser.new
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
            Cro::HTTP::BodyParser::JSON.new
        ]
    );

If both `body-parsers` and `add-body-parsers` is used, then both will be used,
with those in `add-body-parsers` again having higher precedence.

A similar scheme applies for body serializers. Use `add-body-serializers` to
add extra ones to the defaults:

    my Cro::Service $hello-service = Cro::HTTP::Server.new(
        :host('localhost'), :port(8888), :$application,
        add-body-serializers => [
            YAMLBodySerializer.new,
            XMLBodySerializer.new
        ]
    );

Or replace the set of body serializers entirely by passing `body-serializers`:

    my Cro::Service $hello-service = Cro::HTTP::Server.new(
        :host('localhost'), :port(8888), :$application,
        body-serializers => [
            # The body can only ever be something that can be JSON serialized.
            Cro::HTTP::BodySerializer::JSON.new
        ]
    );

If both `add-body-serializers` and `body-serializers` are passed, they both
will be used, with those in `add-body-serializers` taking precedence.

## Middleware

HTTP middleware is implemented as a `Cro::Transform`. There are four places
that HTTP middleware can be inserted. There are, in order of processing:

* **before-parse** - operates on the raw bytes coming over the network prior
  to the `Cro::HTTP::RequestParser` seeing them. The transform should consume
  a `Cro::TCP::Message` and produce a `Cro::TCP::Message`. It is relatively
  unusual to need to insert middleware at this stage, though it could be
  useful for getting rate limiting in early before the effort to even parse
  a request has been expended, for example.
* **before** - operates on requests after they have been parsed, but before
  they reach the application. Consumes a `Cro::HTTP::Request` and produces a
  `Cro::HTTP::Request`.  This is a common place to put middleware that does
  authentication, authorization, session handling, CSRF protection, and so
  forth.
* **after** - operates on responses produced by the application. Consumes a
  `Cro::HTTP::Response` and produces a `Cro::HTTP::Response`. This is a common
  place to put middleware that does things like logging and inserting headers
  to increase security (like `X-Frame-Options`, `Strict-Transport-Security`,
  `Content-Security-Policy`, and so forth).
* **after-serialize** - operates on the bytes sent back over the network in
  response to a request. Consumes a `Cro::TCP::Message` and produces a
  `Cro::TCP::Message`. It is unusual to need to insert middleware at this
  stage.

The names of these places are named parameters that can be passed to the
`Cro::HTTP::Server` constructor. Either a single `Cro::Transform` or an
`Iterable` (for example, `List`) of `Cro::Transform`s may be passed.

For example, the following piece of middleware:

```
    class StrictTransportSecurity does Cro::Transform {
        has Duration:D $.max-age is required;

        method consumes() { Cro::HTTP::Response }
        method produces() { Cro::HTTP::Response }

        method transformer(Supply $pipeline --> Supply) {
            supply {
                whenever $pipeline -> $response {
                    $response.append-header:
                        'Strict-Transport-Security',
                        "max-age=$!max-age";
                    emit $response;
                }
            }
        }
    }
```

Could be applied as follows:

    my Cro::Service $hello-service = Cro::HTTP::Server.new(
        :host('localhost'), :port(8888), :$application,
        after => ScriptTransportSecurity.new(Duration.new(30 * 24 * 60 * 60))
    );

## HTTP versions

The `:http` option can be passed to control which versions of HTTP should be
supported. It can be passed a single item or list. Valid options are `1.1`
(which will implicitly handle HTTP/1.0 too) and `2`.

    :http<1.1>      # HTTP/1.1 only
    :http<2>        # HTTP/2 only
    :http<1.1 2>    # HTTP/1.1 and HTTP/2 (SSL only; selected by ALPN)

The default is `:http<1.1>` for a HTTP server. For a HTTPS server, if the SSL
library (`IO::Socket::Async::SSL`) detects that ALPN support is available then
it will default to `:http<1.1 2>`; otherwise it will default to `:http<1.1>`.
If `:http<1.1 2>` is specified and ALPN support is not available, then an
exception will be thrown. ALPN is the only supported mechanism for selecting
between HTTP/1.1 and HTTP/2, thus the requirement on it for this configuration
(and why there is no option for both versions with HTTP).
