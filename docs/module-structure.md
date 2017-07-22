# Cro Module Structure

Cro is split into a number of modules, which may be installed independently.
This means that containers for services can be kept samller, for example by
only including the parts of Cro that they are using. It also allows for any
modules depending on Cro to depend on just the parts they need.

## Cro::Core

The `Cro::Core` package contains key Cro infrastructure:

* The key `Cro` roles (`Cro::Source`, `Cro::Transform`, and so forth)
* The `Cro` composer along with its default connection manager
* The `Cro::Uri` and `Cro::MediaType` value types
* The `Cro::TCP` module, providing TCP support

All other Cro modules ultimately depend on this.

## Cro::SSL

The `Cro::SSL` package contains the `Cro::SSL` module, which provides SSL
support.

## Cro::HTTP

This module includes:

* `Cro::HTTP::Client` (for making HTTP requests)
* `Cro::HTTP::Server` and `Cro::HTTP::Router` (for building HTTP services)
* HTTP message body parsers and serializers for `multipart/form-data`,
  `application/x-www-form-urlencoded`, and JSON
* HTTP/1.1 and HTTP/2 request/response parsers and serializers
* HTTP version selection and connection management infrastructure

It depends on `Cro::Core` and `Cro::SSL`.

## Cro::WebSocket

This module includes:

* `Cro::WebSocket::Client`
* `Cro::HTTP::Router::WebSocket` (`Cro::HTTP::Router` plugin for web sockets)
* Web socket protocol parsers and serializers

It depends on `Cro::HTTP`.

## Cro::ZeroMQ

This module provides support for ZeroMQ pipelines in Cro.

## cro

The Cro development tools. Includes:

* The `cro` command line tool
* The `cro web` web interface for Cro development

It depends on `Cro::WebSocket`, and thus `Cro::HTTP`, `Cro::SSL`, and
`Cro::Core`. Therefore, it always provides support for stubbing HTTP services.
If `Cro::ZeroMQ` is installed then it will provide the option to stub ZeroMQ
services also.
