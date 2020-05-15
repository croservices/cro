# The Cro approach

At its heart, Cro is all about building up chains of Raku supplies that
process messages that arrive from the network and produce messages to be sent
over the network.

## Key roles

Messages are represented by `Cro::Message`. Concrete implementations include:

* `Cro::TCP::Message`
* `Cro::HTTP::Request`
* `Cro::HTTP::Response`

Incoming connections are represented by `Cro::Connection`; implementations
include:

* `Cro::TCP::ServerConnection`
* `Cro::TLS::ServerConnection`

A `Cro::Source` is a source of either messages or connections. For example,
`Cro::TCP::Listener` produces `Cro::TCP::ServerConnection` objects.

A `Cro::Transform` transforms one connection or message into another. For
example, `Cro::HTTP::RequestParser` will transform `Cro::TCP::Message`s into
`Cro::HTTP::Request`s, while a `Cro::HTTP::ResponseSerializer` transforms
`Cro::HTTP::Response`s into `Cro::TCP::Message`s. This means that in Cro,
HTTP applications are simply transforms from `Cro::HTTP::Request` into
`Cro::HTTP::Response`.

A `Cro::Sink` consumes messages. It doesn't produce anything. A sink comes at
the end of a message processing pipeline. A sink in a TCP server would consume
`Cro::TCP::Message`s and send them over the network.

Some messages or connections can be replied to with one or more messages. These
do the `Cro::Replyable` role. Anything that produces a replyable is also
responsible for providing something that can process the reply messages. This
"something" may either be a transform or a sink. Examples of replyables include
`Cro::TCP::ServerConnection` and `Cro::TLS::ServerConnection`, which give a
`Cro::Sink` replier that sends `Cro::TCP::Message` objects back to the client.

## Composition

Cro components (sources, transforms, and sinks) can be put together to form
pipelines. This process is called pipeline composition. Perhaps the simplest
possible example is setting up an echo server:

```
class Echo does Cro::Transform {
    method consumes() { Cro::TCP::Message }
    method produces() { Cro::TCP::Message }

    method reply(Supply $source) {
        # We could actually just `return $source` here, but the identity
        # supply is written out here to illustrate what a transform will
        # often look like.
        supply {
            whenever $source -> $message {
                emit $message;
            }
        }
    }
}
```

Which can then be composed into a service and started as follows:

    my Cro::Service $echo-server = Cro.compose(
        Cro::TCP::Listener.new(port => 8000),
        Echo
    );
    $echo-server.start();

Note that `Cro.compose(...)` only returns a `Cro::Service` in the case that
it has something that starts with a source and ends with a sink. So where did
the sink come from in this case? From the fact that a connection is replyable,
and so it provided the sink. It's also worth noting that a stream of connections
magically turned into a stream of messages. If the composer spots that something
producing connections is followed by something consuming messages, it will
pass the rest of the pipeline to a `Cro::ConnectionManager` instance, so the
processing of the remainder of the pipeline will be per connection.

## An HTTP server example

Most Cro HTTP services will be assembled using high-level modules such as
`Cro::HTTP::Router` and `Cro::HTTP::Server`. However, it is possible to use
`Cro.compose(...)` to piece together a HTTP processing pipeline without these
conveniences. First, various components and message types are needed:

    use Cro;
    use Cro::HTTP::Request;
    use Cro::HTTP::RequestParser;
    use Cro::HTTP::Response;
    use Cro::HTTP::ResponseSerializer;
    use Cro::TCP;

The HTTP application itself - a simple "Hello, world" - is a `Cro::Transform`
that turns a request into a response:

```
class HTTPHello does Cro::Transform {
    method consumes() { Cro::HTTP::Request }
    method produces() { Cro::HTTP::Response }

    method transformer($request-stream) {
        supply {
            whenever $request-stream -> $request {
                given Cro::HTTP::Response.new(:200status) {
                    .append-header('Content-type', 'text/html');
                    .set-body("<strong>Hello from Cro!</strong>");
                    .emit;
                }
            }
        }
    }
}
```

These are composed into a service:

    my Cro::Service $http-service = Cro.compose(
        Cro::TCP::Listener.new( :host('localhost'), :port(8181) ),
        Cro::HTTP::RequestParser.new,
        HTTPHello,
        Cro::HTTP::ResponseSerializer.new
    );

Which can then be used like this:

    $http-service.start;
    signal(SIGINT).tap: {
        note "Shutting down...";
        $http-service.stop;
        exit;
    }
    sleep;

## Client pipelines

Clients, such as HTTP clients, are also expressed as pipelines. Unlike with
server pipelines, where the application is at the center of the pipeline and
the network at either end, a client pipeline has the network at the center and
the application at either end.

The component at the center of a client pipeline will be a `Cro::Connector`,
which establishes a connection. A `Cro::Connector` is able to establish a
connection and produce a `Cro::Transform` that will send messages it consumes
using the connection and emit messages received from the network connection.
Pipelines featuring a connector must not have a `Cro::Source` nor a
`Cro::Sink`.

A minimal TCP client that connects, sends a message, and disconnects as soon
as it has received something, could be expressed as:

    my Cro::Connector $conn = Cro.compose(Cro::TCP::Connector);
    my Supply $responses = $conn.establish(
        host => 'localhost',
        port => 4242,
        supply {
            emit Cro::TCP::Message.new( :data('hello'.encode('ascii')) )
        }
    );
    react {
        whenever $responses {
            say .data;
            done;
        }
    }

The `establish` method on a client establishes a connection. It takes a single
positional argument with a `Supply`, which will be tapped to receive messages
to send; all named arguments will be passed along to the `connect` method,
which which makes a connection and returns a transform. The `establish` method
will return a `Supply` that the response messages will be emitted on.

More complex pipelines are possible. For example, a (not entirely convenient,
but functional) HTTP client would look like:

```
my Cro::Connector $conn = Cro.compose(
    Cro::HTTP::RequestSerializer,
    Cro::TLS::Connector,
    Cro::HTTP::ResponseParser
);

my $req = supply {
    my Cro::HTTP::Request $req .= new(:method<GET>, :target</>);
    $req.add-header('Host', 'www.raku.org');
    emit $req;
}
react {
    whenever $conn.establish($req, :host<www.raku.org>, :port(80)) {
        say ~$response; # Dump headers
    }
}
```
