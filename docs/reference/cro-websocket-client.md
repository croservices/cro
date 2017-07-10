# Cro::WebSocket::Client

The Cro::WebSocket::Client class provides a web socket client. It can
either be instantiated with default configuration (such as a default
URI) or used directly.

## connect

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

The connect method returns a `Promise` that is broken if the
connection can not be made. Otherwise, it is kept with a
`Cro::WebSocket::Client::Connection` object.
