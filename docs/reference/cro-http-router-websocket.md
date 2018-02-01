# Cro::HTTP::Router::WebSocket

This exports a subroutine `web-socket` that is to be used inside of a
`Cro::HTTP::Router` `get` handler. This makes it easy to use WebSockets inside
of a HTTP application built using the router.

## Basic usage

The `web-socket` subroutine takes a code block, which will - per new WebSocket
connection - receive a `Supply` argument. This `Supply` will emit a
`Cro::WebSocket::Message` for each message received from the client. The
block is expected to return a `Supply` that will `emit` messages to be sent to
the client.

Thus, a highly simplified chat server might be written as:

```
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
```

## Receiving close messages

If the block passed to `web-socket` has two parameters, the second one shall
be passed a `Promise` that will be kept with any Close message sent by the
client, or alternatively when the socket is closed from the server side.

```
my $chat = Supplier.new;

get -> 'chat' {
    web-socket -> $incoming, $close {
        supply {
            whenever $incoming -> $message {
                $chat.emit(await $message.body-text);
            }
            whenever $chat -> $text {
                emit $text;
            }
            whenever $close {
                $chat.emit("A user left the chat");
            }
        }
    }
}
```

## Body parsing and serialization

Body parsers (implementing the `Cro::BodyParser` role) and body serializers
(implementing the `Cro::BodySerializer` role) may be passed to `web-socket`.
These allow for easier processing of, for example, JSON messages.

```
use Cro::WebSocket::BodyParsers;
use Cro::WebSocket::BodySerializers;

# Receives JSON messages like:
#   { "input": "देवनागरी" }
# And produces messages like:
#   { "result": 5 }
get -> 'graphemes' {
    web-socket
        :body-parsers(Cro::WebSocket::BodyParser::JSON),
        :body-serializers(Cro::WebSocket::BodySerializer::JSON),
        -> $incoming {
            supply whenever $incoming -> $message {
                my $json = await $message.body;
                emit { result => $json<input>.chars };
            }
        }
}
```

Since working with JSON is so common, there is a shortcut `:json` argument
to `web-socket` that configures the body parser and serializer as seen in the
previous example, reducing it to just:

```
get -> 'graphemes' {
    web-socket :json, -> $incoming {
        supply whenever $incoming -> $message {
            my $json = await $message.body;
            emit { result => $json<input>.chars };
        }
    }
}
```
