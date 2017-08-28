# Cro::HTTP::Router::WebSocket

This exports a subroutine `web-socket` that is to be used inside of a HTTP router `get` handler. This subroutine must take a code block, which takes a `Supply`. This `Supply` will process `Cro::WebSocket::Message` instances for messages received from the client when tapped. The block is expected to return a `Supply` that will emit response messages.

A simple example:

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

The second optional parameter to the block is a `Promise` that will be kept after `Supply` is `done`.

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
