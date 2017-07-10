# Cro::WebSocket::FrameSerializer

The class represents a serializer for frames and is implemented as
`Cro::Transform` that consumes `Cro::WebSocket::Frame` and produces
`Cro::TCP::Message`. It can be configured with a boolean parameter
`mask`. If set, this will mask the payload.

Everything that is needed for a complete serialization and is not
specified in `Cro::WebSocket::Frame` instance is calculated inside of
serializer: correct length is set, mask(if needed) is generated and
the payload is masked.
