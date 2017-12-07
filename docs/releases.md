# Cro Release History

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
