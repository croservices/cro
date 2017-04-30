# The Crow approach

At its heart, Crow is all about building up chains of Perl 6 supplies that
process messages that arrive from the network and produce messages to be sent
over the network.

## Key roles

Messages are represented by `Crow::Message`. Concrete implementations include:

* Crow::TCP::Message
* Crow::HTTP::Request
* Crow::HTTP::Response

A `Crow::Source` is a source of either messages or connections. For example,
`Crow::TCP::Listener` produces `Crow::TCP::ServerConnection` objects.

A `Crow::Transform` transforms one connection or message into another. For
example, `Crow::HTTP::RequestParser` will transform `Crow::TCP::Message`s into
`Crow::HTTP::Request`s, while a `Crow::HTTP::ResponseSerializer` transforms a
`Crow::HTTP::Response`s into `Crow::TCP::Messages`s. This means that in Crow,
HTTP applications are simply transforms from `Crow::HTTP::Request` into
`Crow::HTTP::Response`.

A `Crow::Sink` consumes messages. It doesn't produce anything. A sink comes at
the end of a message processing pipeline. A sink in a TCP server would consume
`Crow::TCP::Message`s and send them over the network.

Some messages or connections can be replied to with one or more messages. These
do the `Crow::Replyable` role. Anything that produces a replyable is also
responsible for providing something that can send response messages. This
"something" may either be a transform or a sink. Examples of replyables include
`Crow::TCP::ServerConnection` and `Crow::SSL::ServerConnection`.

## Composition

Crow components (sources, transforms, and sinks) can be put together to form
pipelines. This process is called pipeline composition. Perhaps the simplest
possible example is setting up an echo server:

    class Echo does Crow::Transform {
        method consumes() { Crow::TCP::Message }
        method produces() { Crow::TCP::Message }
        
        method reply(Supply $source) {
            # We could actually just `return $source` here, but the identity
            # supply is written out here for good measure.
            supply {
                whenever $source -> $message {
                    emit $message;
                }
            }
        }
    }

Which can then be composed into a service and started as follows:

    my Crow::Service $echo-server = Crow.compose(
        Crow::TCP::Listener.new(port => 8000),
        Echo
    );
    $echo-server.start();

Note that `Crow.compose(...)` only returns a `Crow::Service` in the case that
it has something that starts with a source and ends with a sink. So where did
the sink come from in this case? From the fact that a connection is replyable,
and so it provided the sink. It's also worth noting that a stream of connections
magically turned into a stream of messages. If the composer spots that something
producing connections is followed by something consuming messages, it will
pass the rest of the pipeline to a `Crow::ConnectionManager` instance, so the
processing of the remainder of the pipeline will be per connection.

## An HTTP server example

Most Crow HTTP services will be assembled using high-level modules such as
`Crow::HTTP::Router` and `Crow::HTTP::Server`. However, it is possible to use
`Crow.compose(...)` to piece together a HTTP processing pipeline without these
conveniences. First, various components and message types are needed:

    use Crow;
    use Crow::HTTP::Request;
    use Crow::HTTP::RequestParser;
    use Crow::HTTP::Response;
    use Crow::HTTP::ResponseSerializer;
    use Crow::TCP;

The HTTP application itself - a simple "Hello, world" - is a `Crow::Transform`
that turns a request into a response:

    class HTTPHello does Crow::Transform {
        method consumes() { Crow::HTTP::Request }
        method produces() { Crow::HTTP::Response }

        method transformer($request-stream) {
            supply {
                whenever $request-stream -> $request {
                    given Crow::HTTP::Response.new(:200status) {
                        .append-header('Content-type', 'text/html');
                        .set-body("<strong>Hello from Crow!</strong>".encode('ascii'));
                        .emit;
                    }
                }
            }
        }
    }

These are composed into a service:

    my Crow::Service $http-service = Crow.compose(
        Crow::TCP::Listener.new( :host('localhost'), :port(8181) ),
        Crow::HTTP::RequestParser.new,
        HTTPHello,
        Crow::HTTP::ResponseSerializer.new
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

The component at the center of a client pipeline will be a `Crow::Connector`,
which establishes a connection. A `Crow::Connector` is able to establish a
connection and produce a `Crow::Transform` that will send mesages it consumes
using the connection and emit messages received from the network connection.
Pipelines featuring a connector must not have a `Crow::Source` nor a
`Crow::Sink`.

A minimal TCP client that connects, sends a message, and disconnects as soon
as it has received something, could be expressed as:

    my Crow::Connector $conn = Crow.compose(Crow::TCP::Connector);
    my Supply $responses = $tcp-client.establish(
        host => 'localhost',
        port => 4242,
        supply {
            emit Crow::TCP::Message.new( :data('hello'.encode('ascii')) )
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

    my Crow::Connector $conn = Crow.compose(
        Crow::HTTP::RequestSerializer,
        Crow::SSL::Connector,
        Crow::HTTP::ResponseParser
    );

    my $req = supply {
        my Crow::HTTP::Request $req .= new(:method<GET>, :target</>);
        $req.add-header('Host', 'www.perl6.org');
        emit $req;
    }
    react {
        whenever $conn.establish($req, :host<www.perl6.org>, :port(80)) {
            say ~$response; # Dump headers
        }
    }
