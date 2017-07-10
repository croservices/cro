# Cro::WebSocket::FrameParser

This class represents frame parser, implemented as `Cro::Transform`
that consumes `Cro::TCP::Message` and produces
`Cro::WebSocket::Frame`.  It makes no attempt to interpret the
meanings of frames (for example, it doesn't decode binary to text, nor
try to piece together continuation frames into complete messages). If
there is a mask, the payload data will be unmasked.

# mask-required

The parser may be configured with the boolean parameter mask-required,
which will be set by a server and not set by a client.  If the mask
bit in the frame doesn't match this flag, then the frame parser will
throw an `X::Cro::WebSocket::IncorrectMaskFlag` exception instance.
