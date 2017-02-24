# The Crow approach

At its heart, Crow is all about building up chains of Perl 6 supplies that
process messages that arrive from the network and produce messages to be sent
over the network.

## Key roles

Messages are represented by `Crow::Message`. Concrete implementations include:

* Crow::TCP::Message
* Crow::HTTP::Request
* Crow::HTTP::Response
* Crow::ZeroMQ::Message

A `Crow::Source` is a source of either messages or connections. For example,
`Crow::TCP::Listener` produces `Crow::TCP::Connection`s.

A `Crow::Transform` transforms one thing into another, where said things may
be either connections or messages. For example, `Crow::HTTP::RequestParser`
will transform `Crow::TCP::Message`s into `Crow::HTTP::Request`s.

A `Crow::Sink` consumes messages. It doesn't produce anything. A sink comes at
the end of a message processing pipeline.

Some messages or connections can be replied to with one or more messages. These
do the `Crow::Replyable` role. Anything that produces a replyable is also
responsible for providing something that can send response messages. This
"something" may either be a transform or a sink. Examples of replyables include
both `Crow::HTTP::Request` and `Crow::TCP::Connection`.

## Composition

Crow components (sources, transforms, repliers, and sinks) can be combined
together to form pipelines. Perhaps the simplest possible example is setting
up an echo server.

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
