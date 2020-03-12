# Cro documentation

## Introductory Material

The essentials you need to know to get building with Cro:

* [Getting Started](docs/intro/getstarted)
* [Creating HTTP Services](docs/intro/http-server)
* [Making HTTP Requests](docs/intro/http-client)
* [Building a Single Page Application with Cro and React/Redux](docs/intro/spa-with-cro)

## Beyond The Basics

Ready to dig a deeper? These articles explain the Cro design and structure,
as well as covering some more advanced topics:

* [The Cro Approach](docs/approach)
* [Cro Module Structure](docs/module-structure)
* [The cro Development Tool](docs/cro-tool)
* [The .cro.yml File](docs/cro-yml)
* [Structuring larger HTTP services and applications](docs/structuring-services)
* [Docker Deployment with Cro](docs/docker-deployment)

## Getting Help

* Post your question on [Stack Overflow](https://stackoverflow.com/) (be sure
  to tag it `perl6` and `cro`)
* Visit the `#cro` IRC channel on freenode
* Get [commercial support and training](/training-support)

## Reference

The full details, organized by module:

### Cro::Core

* [Cro::MediaType](docs/reference/cro-mediatype)
* [Cro::Uri](docs/reference/cro-uri)

### Cro::TLS

* [Cro::TLS](docs/reference/cro-tls)

### Cro::HTTP

Client side:

* [Cro::HTTP::Client](docs/reference/cro-http-client)
* [Cro::HTTP::Client::CookieJar](docs/reference/cro-http-client-cookiejar)

Server side:

* [Cro::HTTP::Router](docs/reference/cro-http-router)
* [Cro::HTTP::Server](docs/reference/cro-http-server)
* [Cro::HTTP::Middleware](docs/reference/cro-http-middleware)
* [HTTP Sessions and Authentication](docs/http-auth-and-sessions)

Requests, responses, and related types:

* [Cro::HTTP::Cookie](docs/reference/cro-http-cookie)
* [Cro::HTTP::DateTime](docs/reference/cro-http-datetime)
* [Cro::HTTP::Message](docs/reference/cro-http-message)
* [Cro::HTTP::Request](docs/reference/cro-http-request)
* [Cro::HTTP::Response](docs/reference/cro-http-response)

### Cro::HTTP::Test

* [Cro::HTTP::Test](docs/reference/cro-http-test)

### Cro::WebSocket

For application developers:

* [Cro::HTTP::Router::WebSocket](docs/reference/cro-http-router-websocket)
* [Cro::WebSocket::Client](docs/reference/cro-websocket-client)
* [Cro::WebSocket::Message](docs/reference/cro-websocket-message)

Pipeline components:

* [Cro::WebSocket::Frame](docs/reference/cro-websocket-frame)
* [Cro::WebSocket::FrameParser](docs/reference/cro-websocket-frameparser)
* [Cro::WebSocket::FrameSerializer](docs/reference/cro-websocket-frameserializer)
* [Cro::WebSocket::Handler](docs/reference/cro-websocket-handler)
* [Cro::WebSocket::MessageParser](docs/reference/cro-websocket-messageparser)
* [Cro::WebSocket::MessageSerializer](docs/reference/cro-websocket-messageserializer)

### Cro::WebApp

* [Cro::WebApp::Form](docs/reference/cro-webapp-form)
* [Cro::WebApp::Template](docs/reference/cro-webapp-template)

### Cro::OpenAPI::RoutesFromDefinition

* [Cro::OpenAPI::RoutesFromDefinition](docs/reference/cro-openapi-routesfromdefinition)

### Cro::ZeroMQ

* [Cro::ZeroMQ](docs/reference/cro-zeromq)

### Cro::Tools

The development tools are mostly without API docs, as they are mostly not
expected to be extended from the outside at this point. However, the following
parts have stable APIs for the sake of extending the tools:

* [Cro::Tools::LinkTemplate](docs/reference/cro-tools-linktemplate)
* [Cro::Tools::Template](docs/reference/cro-tools-template)

## Meta

* [Release notes](docs/releases)
---
