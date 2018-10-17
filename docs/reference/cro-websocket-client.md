# Cro::WebSocket::Client

The Cro::WebSocket::Client class provides a web socket client. It can
either be instantiated with default configuration (such as a default
URI) or used directly.

## Connecting

To connect without making an instance, use the connect method with a
URI:

    my $conn = await Cro::WebSocket::Client.connect:
        'ws://some.host:1234/path/to/chat';

To connect securely, use a wss URI:

    my $conn = await Cro::WebSocket::Client.connect:
        'wss://some.host:1234/path/to/chat';
    
If many connections shall be made to the same web socket server over
time, it can be convenient to factor that out by passing the URI to
the constructor:

    my $client = Cro::WebSocket::Client.new: uri =>
        'ws://some.host:1234/path/to/chat';
    
The `connect` method may then be used without an argument:

    my $conn = await $client.connect();

It is an error to call `connect` without a URI if none was set at construction
time. If a URI is passed to the constructor and to `connect`, then the one
given to `connect` will be treated as a URI reference.

The `connect` method returns a `Promise` that is broken if the connection can
not be made. Otherwise, it is kept with a `Cro::WebSocket::Client::Connection`
object, which can be used to communicate over the WebSocket.

To pass extra headers with the WebSocket handshake HTTP request, pass a list
of them with the `headers` named argument. They can be passed as `Pair`s or
as instances of `Cro::HTTP::Header`.

    my $client = Cro::WebSocket::Client.new:
        uri => 'ws://some.host:1234/path/to/chat',
        headers => [
            referer => 'http://anotherexample.com',
            Cro::HTTP::Header.new(
                name => 'User-agent',
                value => 'Cro'
            )
        ];

## Send messages

Call the `send` method on the connection to send a message. One can pass:

* An instance of `Cro::WebSocket::Message` (least convenient, but most
  flexible; all other options described here are convenience forms that
  make a `Cro::WebSocket::Message`)
* A `Str`, in which case a text message will be sent
* A `Blob`, in which case a binary message will be sent
* A `Supply`, which should emit `Blob`s; each one will be sent as a
  frame, allowing fragmentation of large messages
* Any other object, which will be serialized using the body serializers set
  on the client (described later). For example, a client constructed with
  `:json` will automatically serialize sent objects to JSON.

For example:

    $connection.send('Some unimaginative example string');

The message is sent asynchronously, and `send` returns immediately.

## Receive messages

The `messages` method on the client returns a `Supply`, which can be tapped
to receive messages that arrive over the WebSocket connection. The message
is represented by the `Cro::WebSocket::Message` class.

```
react {
    whenever $connection.messages -> $message {
        whenever $message.body -> $body {
            # Process the body
        }
    }
}
```

By default, the `body` method provides a `Blob` for a binary message and a
`Str` for a text message. However, it's possible to configure body parsers
to apply deserialization. For example, a client constructed with `:json`
will perform JSON deserialization on all messages

## Closing the connection

Call the `close` method to close the WebSocket connection. If wishing to
specify the close code pass it as an argument, otherwise, a default code
of `1000` will be used.

    $connection.close(2000);

The `close` method returns a `Promise` that will be kept once the connection
has been gracefully closed. To specify a timeout, pass the `timeout` named
argument. A timeout of zero sends a forceful termination and immediately
closes the connection.

    await $connection.close(timeout => 2);  # 2s timeout
    $connection.close(:!timeout);     # forceful close, no timeout

## Ping

To test if the connection is still alive, call `ping`. It returns a `Promise`
that will be kept when a pong is received from the server.

    await $connection.ping();

A timeout can also be specified in seconds:

    await $connection.ping(timeout => 5);

It is also possible to send binary (`Blob`) or text (`Str`) data with the ping
(this mechanism does not apply body serialization, however).

    await $connection.ping('Anybody there?', timeout => 5);

## Body Parsing and Serialization

It is possible to instantiate the client with body parsers and serializers.
These allow for sending of objects other than `Str` and `Blob`. For example,
By instantiating the client with a JSON parser and serializer:

```
use Cro::WebSocket::BodyParsers;
use Cro::WebSocket::BodySerializers;

my $client = Cro::WebSocket::Client.new:
    body-parsers => Cro::WebSocket::BodyParser::JSON,
    body-serializers => Cro::WebSocket::BodySerializer::JSON;
```

Then it is possible to `send` an object (`Hash` or `List`) on a connection,
and have it serialized automatically. Similarly received messages will have
the `body` property return a `Promise` that will be kept with a deserialized
JSON object.

Since this JSON combination is so common, the above example can simply be
written as:

```
my $client = Cro::WebSocket::Client.new: :json;
```

Implement the `Cro::BodyParser` and `Cro::BodySerializer` roles in order to
create custom body parsers and serializers for use with the WebSocket client.
