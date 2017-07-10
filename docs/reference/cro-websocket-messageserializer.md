# Cro::WebSocket::MessageSerializer

A `Cro::Transform` that consumes `Cro::WebSocket::Message` and
produces `Cro::WebSocket::Frame`. It handles Message bufferization,
e.g. all emitted `Frame`s will be sent in a correct order. However, if
control message is received(i.e. one with `opcode` equal to `Close`,
`Ping` or `Pong`), it will be emitted as soon as possible.
