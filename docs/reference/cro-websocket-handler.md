# Cro::WebSocket::Handler

This is a `Cro::Transform` that consumes `Cro::WebSocket::Message` and
produces `Cro::WebSocket::Message`. It takes care of automatically
responding to ping messages with a pong message. The only requirement
is that it is passed a code block. That block may taking a single
parameter, which will be a `Supply` of incoming messages. It is expect
to return a `Supply` that, when tapped, will process
messages. Anything it emits will be considered a response message.

```
my $uc-ws = Cro::WebSocket::Handler.new(
    -> $incoming {
        supply {
            whenever $incoming -> $message {
                my $body = await $message.body-text();
                emit Cro::WebSocket::Message.new($body.uc);
            }
        }
    }
)
```

The incoming `Supply` will be done when a `Close` frame is
received. In some cases, the content of the closing frame may be of
interest. In this case, an arity two block may be passed, which will
receive a `Promise` that is kept with the close message.

```
my $uc-ws = Cro::WebSocket::Handler.new(
    -> $incoming, $close {
        supply {
            whenever $incoming -> $message {
                my $body = await $message.body-text();
                emit Cro::WebSocket::Message.new($body.uc);
            }
            whenever $close -> $message {
                say "Close body: " ~ await($message.body-blob).gist;
            }
        }
    }
)
```

If a message of type `Close` is emitted, then it will be sent and the
tap on the `Supply` will be closed. Otherwise, when the returned
`Supply` is done, then a `Close` message will be sent automatically
with the close reason of `1000` (normal closure). Alternatively, if
the `Supply` is terminated with a `quit` (due to an unhandled
exception), a `Close` message will be sent with the close reason of
`1011` (unexpected condition). In any event, it will be ensured that
only one `Close` frame is ever sent (for example, it a `Close` frame
was emitted explicitly and then the `Supply` was done or quit, a
further `Close` frame would never be emitted).

As a convenience, a `Str`, `Blob`, or `Supply` may be emitted instead
of a `Cro::WebSocket::Message`. In this case, it will be passed to the
`new` method of `Cro::WebSocket::Message` and the resulting message
sent. Therefore, the previous example could be written as simply:

```
my $uc-ws = Cro::WebSocket::Handler.new(
    -> $incoming {
        supply {
            whenever $incoming -> $message {
                my $body = await $message.body-text();
                emit $body.uc;
            }
        }
    }
)
```
