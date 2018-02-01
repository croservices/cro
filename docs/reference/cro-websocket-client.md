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
    
The connect method may then be used without an argument:

    my $conn = await $client.connect();

It is an error to call connect without a URI if none was set at
construction time. If a URI is passed to the constructor and to
connect, then it will be appended.

The connect method returns a `Promise` that is broken if the connection can
not be made. Otherwise, it is kept with a `Cro::WebSocket::Client::Connection`
object, which can be used to communicate over the WebSocket.

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
