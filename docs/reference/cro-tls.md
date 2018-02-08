# Cro::TLS

The `Cro::TLS` module contains a number of classes enabling the use of TLS in
Cro pipelines.

## Cro::TLS::Listener

The `Cro::TLS::Listener` class is a `Cro::Source`. It is constructed with the
`port` named argument, and an optional `host` named argument (which defaults
to `localhost`). Any further named arguments will be passed along to
`IO::Socket::Async::SSL.listen`, providing full access to that module's
feature set.

Typically, the keys `private-key-file` and `certificate-file` should be passed,
which indicate the files containing the private key and certificate for the
server. The `alpn` key may be passed to configure protocols available for
Application Level Protocol Negotiation.

    my $listener = Cro::TLS::Listener.new(
        port => 443,
        host => '127.0.0.1',
        private-key-file => 'certs-and-keys/server-key.pem',
        certificate-file => 'certs-and-keys/server-crt.pem'
    );

This source produces `Cro::TLS::ServerConnection` objects.

## Cro::TLS::ServerConnection

The `Cro::TLS::ServerConnection` class does the `Cro::Connection` role and
represents an incoming TLS connection. It produces `Cro::TCP::Message` objects
when data is received over the network, making it easy to write transforms
that can be hosted with both TCP and TLS endpoints.

The class also implements `Cro::Replyable`, with the replier being a sink that
consumes `Cro::TCP::Message` and send them to the client.

The class has a method `alpn-result`, which - if ALPN was used - indicates the
outcome of the protocol negotiation.

## Cro::TLS::Connector

The `Cro::TLS::Connector` class does the `Cro::Connector` role, and is used
for establishing an TLS connection. The `establish` method takes the `port`
named argument (which is required) and the `host` named argument. Any further
named arguments will be passed along to `IO::Socket::Async::SSL.connect`,
making the full range of functionality of that module available.

The connector consumes and produces `Cro::TCP::Message` instances, allowing it
to be used as a drop-in replacement for `Cro::TCP::Connector`.
