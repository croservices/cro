# Cro Release History

## 0.7.5

This release brings two major new features:

* The `Cro::OpenAPI::RoutesFromDefinition` module, which supports implementing
  services specified using an [OpenAPI v3](https://github.com/OAI/OpenAPI-Specification)
  document without needing to repeat the routes, validation, and so forth
  from the document. This work was funded by [Nick Logan (ugexe)](https://deathbyperl6.com/).
  Three modules for wider Perl 6 use were produced and released as part of
  this work: `JSON::Pointer`, `OpenAPI::Model`, and `OpenAPI::Schema::Validate`.
* The `Cro::HTTP::Test` module, which offers a convenient way to write tests
  for HTTP services. It is, of course, primarily aimed at those services built
  using Cro, but may also be provided with a URI as the test target rather than
  a Cro application, and thus can be used to write tests for any HTTP service.
  This work was funded by [Oetiker+Partner](https://www.oetiker.ch/).

The following changes were made to the `Cro::Core` distribution:

* Add `parse-relative` and `parse-ref` to `Cro::Uri`, which parse a relative
  URI and a URI reference (either relative or absolute URI) respectively
* Provide an `add` method to `Cro::Uri`, which implements relative URI
  reference resolution
* When a `Cro::Uri` is constructed with an authority component but no
  host, parse the authority component
* The `Str` method on `Cro::Uri` now assembles the string from the URI
  components, rather than depending on retaining the original URI

The following changes were made to the `Cro::HTTP` distribution:

* Use the new `Cro::Uri.add(...)` method to implement the `base-uri` feature
  of `Cro::HTTP::Client`, making it vastly more correct
* Make it possible to replace the `Cro::HTTP::Client` connector pipeline
  component when subclassing the client
* Make `:@query` parameters in `Cro::HTTP::Router` reflect the original query
  string order

The following changes were made to the `Cro::WebSocket` distribution:

* Make matching of the `Upgrade` header's value case-insensitive, so as to
  permit the `WebSocket` some servers send instead of `websocket`.

The following changes were made to the `Cro` distribution:

* Add documentation for `Cro::HTTP::Test`
* Add documentation for `Cro::OpenAPI::RoutesFromDefinition`
* Document new features for `Cro::Uri`, as well as others that existed, but
  were missing from the documentation

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington
from [Edument](http://cro.services/training-support). We would like to thank
[Nick Logan (ugexe)](https://deathbyperl6.com/) and [Oetiker+Partner](https://www.oetiker.ch/)
for supporting the key new features found in this release.

## 0.7.4

This release brings a number of new features, along with some bug fixes. The
Cro team now provides [Docker base images](https://hub.docker.com/r/croservices/)
for aiding deployment of Cro services. The `cro stub` command also generates a
`Dockerfile` that uses these base images, meaning stubbed services can be
built into a container without any further work.

The following changes were made to the `Cro::Core` distribution:

* Add relative URL parsing support to `Cro::Uri`
* Add `Cro::Iri`, a class for parsing and working with Internationalized
  Resource Identifiers

The following changes were made to the `Cro::HTTP` distribution:

* Make the `static` router function accept an `IO::Path` as the first (base
  directory) argument
* Make the `static` router function slurp up the rest of its positional
  arguments and use them as the path below the base; previously, it took
  an optional array
* Make the `static` router function support an `:indexes[...]` option, which
  configures files that should be served as a directory index
* Switch to using the `DateTime::Parse` module instead of having our own
  such parser
* Make `Cro::HTTP::Router::RouteSet` more subclass-friendly, by making a
  number of attributes public and exposing the `Handler` base role
* Implement `cookies` option to `Cro::HTTP::Client`, for setting cookies to be
  sent with the request
* Make `Cro::HTTP::Client` more tolerant of an SSL library with no ALPN support
  under default usage

The following changes were made to the `Cro::WebSocket` distribution:

* Make `Upgrade` header matching case-insensitive

The following changes were made to the `cro` distribution:

* Generate a `Dockerfile` in HTTP projects produced by `cro stub`
* Provide Docker deployment documentation
* Follow changes in Webpack 4.0 in the SPA tutorial
* Make `cro serve` serve some common directory index files
* Document new `static` features
* Correct session example in documentation to do `Cro::HTTP::Auth`
* Fix `watch-dir` test on OSX
* Don't remove digits in environment variable names when mangling the service
  ID in `cro stub`
* Write a `.gitignore` file as part of `cro stub`
* Be a bit more liberal with runner test timeout, for slower systems

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington
from [Edument](http://cro.services/training-support), together with the
following community members: Geoffrey Broadwell, Itsuki Toyota, Nick Logan,
scriplit, Tobias Leich.

## 0.7.3

This release brings a range of new features, fixes, and improvements. The key
new features include support for HTTP/2.0 push promises (both server side and
client side), HTTP session support (which makes authentication/authorization
far easier to handle), body parser/serialization support in WebSockets, and
a UI for manipulating inter-service links in `cro web`.

Body parsing has been refactored with this release, the `Cro::HTTP::BodyParser`
and `Cro::HTTP::BodySerializer` roles (and their related selector roles) now
living in `Cro::Core` (as `Cro::BodyParser` and so forth). Further, various
body-related infrastructure is in the new `Cro::MessageWithBody` role, which
is used in both the HTTP and WebSocket message objects. This is the only
intended backward-incompatible change in this release, and will only impact
those who have written custom body parsers and serializers. Thankfully, the
changes should be no more than simply deleting `::HTTP` from the role names.

A more detailed summary of the changes follows.

The following changes were made to the `Cro::Core` distribution:

* Lower default limit of binary blob trace output to 512 bytes
* Add `Cro::BodyParser`, `Cro::BodyParserSelector`, `Cro::BodySerializer`,
  and `Cro::BodySerializerSelector` roles, based on those previously in
  the `Cro::HTTP` distribution
* Add `Cro::MessageWithBody` role to factor out the commonalities of body
  handling between HTTP and WebSockets (and, in the future, ZeroMQ)

The following changes were made to the `Cro::HTTP` distribution:

* Add `auth` attribute to `Cro::HTTP::Request`, which can be used to carry
  an "authority" object (session, authorization, etc.)
* Support getting a request's `auth` into an initial route argument in the
  router
* Implement `Cro::HTTP::Session::InMemory` middleware, for in-memory sessions
* Provide a base role (`Cro::HTTP::Session::Persistent`) for implementing
  persistent sessions
* Implement `Cro::HTTP::Auth::Basic` middleware
* Implement JWT (JSON Web Token) authorization middleware
* Implement support for HTTP/2.0 push promises, both client and server side
* Correctly configure HTTPS for the HTTP/2.0 security profile when HTTP/2.0
  is being used (improvements were contributed to the `IO::Socket::Async::SSL`
  module also)
* Various fixes to HTTP/2.0 header handling (fixes were contributed to the
  `HTTP::HPACK` module also)
* Correctly handle an empty HTTP/2.0 settings frame
* Refactor to use the body parser and serializer infrastructure now in the
  `Cro::Core` distribution, and remove `Cro::HTTP::BodyParser`,
  `Cro::HTTP::BodySerializer`, and related roles

The following changes were made to the `Cro::WebSocket` distribution:

* Refactor to support body parsers and serializers, both client and server
  side
* Add JSON body parser and serializer for WebSockets
* Add `:json` option to `web-socket` router plug-in and `Cro::WebSocket::Client`
  as a shortcut to use the JSON body parser and serializer
* Fix a data race between the frame and message parser due to failing to create
  fresh frame objects
* Run WebSocket message handlers asynchronously, to avoid blocking on `await`
  of a fragmented message body
* Address an unreliable test

The following changes were made to the `cro` distribution:

* Refactor HTTP application templates for easier extensibility
* Add a `cro stub` template for React/Redux Single Page Applications
* Implement adding and editing inter-service links in the `cro web` UI
* Workaround for a concurrency bug in YAML parsing, which caused tests (and,
  less often, `cro run`) to occasionally fail
* Numerous documentation updates to cover the changes in this release

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington
from [Edument](http://cro.services/training-support). The `cro stub` changes
(including the React/Redux stub) are thanks to Geoffrey Broadwell.

## 0.7.2

This release brings a number of new features making it easier to create and
consume HTTP middleware, as well as support for middleware at a `route` block
level. In tooling, the `cro web` tool now supports adding inter-service links
when stubbing, and there are improvements for those writing templates
for use with `cro stub`. Read on for details of the full set of improvements.

The following changes were made to the `Cro::Core` distribution:

* Factor out trace output repeated code
* Avoid trace output throwing execptions on Windows

The following changes were made to the `Cro::HTTP` distribution:

* Add `Cro::HTTP::Middleware` module, with a range of roles to simplify the
  implementation of middleware. These include `Conditional` (for request
  middleware that may wish to send an early response) and `RequestResponse`
  (for middleware interested in both requests and responses).
* Support `before` and `after` in `route` blocks taking a block argument for
  writing simple inline middleware, together with support for `before`
  middleware to itself produce a response
* Pass named arguments to the `/` route in `Cro::HTTP::Router`
* Fix `Cro::HTTP::Client` handling of the `http-only` flag on cookies
* Add the `PATCH` HTTP method to the default set of those accepted by the
  request parser, add a `patch` method to `Cro::HTTP::Client`, and a `patch`
  function to `Cro::HTTP::Router`

The following changes were made to the `cro` distribution:

* Support creation of inter-service links when stubbing a service in the Cro
  web tool
* Allow F5 to work in the Cro web tool even after navigating to other pages
* Introduce the `Cro::Tools::Template::Common` role to factor out many common
  tasks between stub templates, and use it
* Make existing templates more possible to subclass, to ease adding further
  stubbing templates
* Fix HTTPS service stub generation
* Document new `Cro::HTTP` middleware features
* Document client and router support for the HTTP `PATCH` method
* A range of typo and layout fixes across the documentation

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington
from [Edument](http://cro.services/training-support), together with the
following community members: dakkar, Geoffrey Broadwell, James Raspass, Michal
Jurosz, Timo Paulssen, vendethiel.

## 0.7.1

This is the second public BETA release of Cro, and the first to be distributed
on CPAN. While this doesn't change how you will install Cro, it does provide
the safety of installing a version we've vetted rather than the latest
development commits. This release contains numerous improvements, including
new features, bug fixes, and better documentation.

The following changes were made to the `Cro::Core` distribution:

* Improve message tracing API and output, showing hex dump style output for
  binary data
* Provide a mode for machine-readable trace output
* Always flush handle after producing trace output
* Add a workaround for a `CLOSE` phaser bug

The `Cro::SSL` distribution is deprecated in favor of `Cro::TLS`. In
`Cro::TLS`, the following changes were made:

* Eliminate a workaround for an older `IO::Socket::Async::SSL` bug
* The tests no longer assume the availability of an OpenSSL version with ALPN
* Add a workaround for a `CLOSE` phaser bug

Furthermore, the Cro team contributed bug fixes to `IO::Socket::Async::SSL`.

The following changes were made to the `Cro::HTTP` distribution:

* `Cro::HTTP::Router`
    * Reply with 204 instead of dying when no status is set 
    * Implement `include`
    * Implement `delegate`, with HTTP requests now carrying both the
      `original-target` and having a relative `target`
    * Properly handle `%` sequences in URL segments in HTTP router
    * Partial implementation of per-`route`-block middleware (`before` and
      `after`)
* `Cro::HTTP::Client`
    * Fix an HTTP/1.1 vs HTTP/2.0 detection bug
    * Remove unused attributes in HTTP client internals
    * Fix client to pass on the query string in the target URI
    * Implement `base-uri` constructor argument, which will be prepended to
      all requests made with that client instance
    * Various fixes to HTTPS requests
    * Fix hang in HTTP client on unexpected connection close
* HTTP/2.0 support fixes and improvements
    * Answer HTTP/2.0 pings
    * Don't try to negotiate HTTP/2.0 if ALPN is unavailable
    * Don't run HTTP/2.0 tests without ALPN
    * Don't rely on new HTTP/2.0 streams opening in order
    * Fix a couple of occasional hangs in the HTTP/2.0 client
    * Implement window size handling in HTTP/2.0
* General
    * Correct misspelled body serializer class names
    * Implement new `trace-output` API for better trace output
    * Fix missing `JSON::Fast` dependency
    * Use `Cro::TLS` instead of `Cro::SSL`
    * Make urlencoded and multipart bodies associative, so they can be
      hash-indexed
    * Avoid port conflicts in parallel test runs

The following changes were made to the `cro` distribution:

* `cro` tool
    * Add `cro web`, which launches a web frontend that can perform most of
      the tasks that the command line interface can
    * Implemented tools for working with inter-service links, including link
      templates and the new `cro link` sub-command
    * Make `cro run` inject environment variables with host/port for linked
      services
    * Implement `cro services` command to inspect known services
    * Output service STDOUT on runner's STDOUT, not STDERR
    * Layout tweaks to trace output
    * Correct HTTP service stub's `.cro.yml` generation
    * Default to "no" for HTTPS in HTTP service stub
    * Disarm any Failure found in template locator, avoiding a lot of noise
* Documentation improvements
    * Add a getting started page
    * Add a tutorial showing how to build a single page application using Cro
      and React/Redux
    * Clarify parser/serializer passing
    * Document new `include`, `delegate`, `before`, and `after` functions in
      the HTTP router
    * Fix `created` example
    * Add example of body byte stream use in HTTP client
    * Clear up some confusions in cro-tool docs
    * Correct method name in example for `header-list`
    * Try to organize the docs in the index a bit better
    * Fix many typos and various formatting errors
* Other
    * Harden tests against potential hangs

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington from
[Edument](http://cro.services/training-support), together with the following
community members: Alexander Hartmaier, Alex Chen, Curt Tilmes, Kai Carver,
Karl Rune Nilsen, MasterDuke17, Nick Logan, Salve J. Nilsen, Simon Proctor,
Steve Mynott, and Tom Browder.

## 0.7.0

This was the first public BETA release of Cro.
