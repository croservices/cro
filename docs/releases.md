# Cro Release History

## 0.8.8

This release brings numerous bug fixes and improvements. There are no intended or
known breaking changes.

The improvements center around `Cro::Webapp` templates, which gain a structured
tag syntax that leads to shorter and less error-prone template code. An `elsif`/`else`
syntax and a template comment syntax is also available. Live reload of templates
now also properly accounts for dependencies. Documentation of the template engine
is also divided into a few articles for easier navigation.

The fixes span numerous areas of Cro, and include corrected IRI to URI conversion,
more liberal media type parsing, fixes to HTTP/2.0 semantics, and corrected router
handling of slurpy route path arguments with `where` clauses. Template `<:use ...>`
now properly respects `route`-scoped template locations and can locate templates
from resources.

The following changes were made to the `Cro::Core` distribution:

* Fix parsing of media types of the form `application/x-amz-json-1.1`
* Add a `Str` method to the `Cro::Iri` class
* Fix bugs in IRI to URI conversion

The following changes were made to the `Cro::TLS` distribution:

* Depend on a newer, more stable version of IO::Socket::Async::SSL

The following changes were made to the `Cro::HTTP` distribution:

* Add support for parsing and extracting cookie extensions
* Support `route` block plugins in `before`/`after` blocks (meaning that `Cro::WebApp`'s
  `template` sub can now be used in an `after` block to produce an error page
  response, for example)
* Include the request method and URI in `Cro::HTTP::Client` error messages
* Add a way to get a route handler resource resolver via `route-resource-resolver`
  subroutine, for the benefit of router plugins that wish to work with resources
* Implement HTTP/2.0 remote window handling
* Provide a way to pass arbitrary TLS configuration options down to the
  underlying TLS module in `Cro::HTTP::Client`
* Fix cleanup of timed out connections and make timeout handling more robust
* Fix a bug where using `where` clause on a slurpy route parameter could cause
  an exception
* Fix a bug where the HTTP/2 `END_OF_STREAM` flag was sent twice
* Fix a bug where an incorrect MIME type was set when using the `resource` subroutine
* Add support for the `application/wasm` MIME type
* Fix a bug where percent encoding for a request body did not have enough digits,
  resulting in a protocol violation
* Depend on a newer HTTP::HPACK version which supports more recent Rakudo versions
* Clean up the cookie handling code

The following changes were made to the `Cro::WebApp` distribution:

* Implement conditional structural tags, so that `<?.foo><div>bar</div></?>` can
  instead be written `<?.foo div>bar</?>`
* Implement iteration structural tags, so `<@items><li><$_></li></@>` can instead
  be written `<@items li><$_></@>`
* Provide an `elsif` and `else` syntax in templates (it takes the form
  `<?foo>...</?> <!?bar>...</?> <!>baz</!>`, and works with structured tag
  syntax also
* Provide a syntax for template-level comments (no output send to the client)
  with the delimiters `<#>...</#>`
* Make template live reload account for a template's dependencies
* Ensure that `template-location`s of all kinds are properly respected when
  resolving template `<:use ...>` directives
* Handle the template prelude entirely in the template repository base role,
  to avoid custom template repositories needing to handle it
* Fix subclassing semantics for forms

The following changes were made to the `Cro` distribution:

* Restructure the template documentation so that the template language gets its
  own page, along with dedicated pages for modules and parts
* Document new template features (structured tags, `elsif/else` forms, and comments)
* Document `Cro::HTTP::Log::File`
* Have `cro stub` produce output using modern Raku file extensions

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington from
[Edument](http://cro.services/training-support), together with the following community
members: Brian Duggan, dakkar, Juan Julián Merelo Guervós, Patrick Böker, Sylvain
Colinet, Xliff.

## 0.8.7

This release brings a number of bug fixes and new features, the most significant being
an easy way to set up reverse proxying (where HTTP requests are forwarded to another
server for processing, perhaps with modifications), configurable timeouts in the Cro
HTTP client, and support for separators in Cro template iteration. Those using Cro
templates will also enjoy file/line information from the template file when undefined
values are encountered during template rendering.

The following changes were made to the `Cro::Core` distribution:

* Add a role for timeout policies, along with a default concrete
  timeout policy implementation for staged operations

The following changes were made to the `Cro::TLS` distribution:

* Set minimum version of IO::Socket::Async::SSL module

The following changes were made to the `Cro::HTTP` distribution:

* Add `Cro::HTTP::ReverseProxy`, a reverse proxy transform. Reverse proxies forward requests
  to other HTTP servers. The headers and body can be manipulated in either direction, and
  the target URL selected dynamically based on the request if needed
* Implement support for timeouts in `Cro::HTTP::Client`. Timeouts can be set individually
  for establishing a connection to the server, receiving the response headers, and
  receiving the response body; an overall time budget for the total process can also be
  set
* Fix a memory leak on every connection when middleware was used
* Fix parsing of cookie values wrapped in double quotes
* Report an error on no matching body serializer (using the unhandled error reporter, which
  by default notes in on `$*ERR`)
* Ensure `content` overrides any existing content type header of the response
* Report a likely wrong router implementation case where a signature capture is specified
  instead of a signature

The following changes were made to the `Cro::WebApp` distribution:

* Add a way to render a separator between items in an iteration tag
* Give a better warning when data passed to a template contains a `Nil` or a type object,
  specifying the exact template file and line where the undefined value was encountered
* Allow forms to be rendered with non-POST methods
* Properly display `DateTime` fields in Cro::WebApp::Forms

The following changes were made to the `Cro` distribution:

* Fix some typos in the documentation
* Document new features

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington from
[Edument](http://cro.services/training-support), together with the following community
members: Stefan Seifert, Will "Coke" Coleda, Clifton Wood, James Raspass.

## 0.8.6

This release brings a number of significant improvements.

Cro templates gain a major new feature: template parts, which are primarily useful
for factoring out provision of data for common page elements, such as indicating
the currently logged in user or showing shopping basket size. They also offer an
alternative way to write templates: the `MAIN` part receives the top-level
template data, giving an alternative to accessing everything via the topic
variable.

While it has long been easy to serve static content from files in Cro, it's now
also straightforward to serve them from resources; Cro templates can also be
stored as resources. This makes it far easier to distribute Cro applications via
the module ecosystem.

The `Cro::HTTP::Client` now handles IRIs (International Resource Identifiers),
along with having convenience methods for when one only wants the body of a
response, rather than having to get the response object and then obtain the
body from that. Instead of `get`, call `get-body` (and the same for the
other request methods).

Last but not least, profiling led to the identification of a number of
straightforward performance improvements, and we've measured upto 50% more
requests per second being processed in a simple Cro HTTP application.


The following changes were made to the `Cro::Core` distribution:

* Improve support of IRI and URI, introduce a common role `Cro::ResourceIdentifier`
  as well as a package named the same way containing the `decode-percents`,
  `encode-percents` and `encode-percents-excvept-ASCII` subroutines
* Add methods `parse-relative` and `parse-ref` to `Cro::Iri`
* The IRI parser now handles URI and both IRI and URI now support URI with
  forbidden characters such as `[` and automatically encodes them as RFC 3986 suggests
* Fix a bug with padding in the `encode-percents` subroutine

The following changes were made to the `Cro::HTTP` distribution:

* Improve the performance of a Cro HTTP application up to 50%
  more requests per second
* Add a router plugin mechanism which is used to make `template-resources`
  serve templates from the distribution resources, allow the `template-location`
  subroutine to respect the route block structure and configure a resource
  hash that will will be used for serving static content.
  Its API is documented and can be utilized for writing extensions
  for the Cro HTTP router.
* The `Cro::HTTP::Client` now accepts IRI, a Unicode superset of
  URI, and automatically encodes the given IRI so that it will
  be understood by the server
* Add a family of `*-body` methods to `Cro::HTTP::Client`
  which are shortcuts for an await for the response and an
  await for the body, corresponding to HTTP methods (such as
  `get-body`, `post-body`, `put-body`, `delete-body`, `path-body`
  and generic `request-body`)
* Add a `quality-header` for the `Cro::HTTP::Message`
* Warn if a `route` block is sunk (most likely a forgotten
  `include` or `delegate` call)

The following changes were made to the `Cro::WebSocket` distribution:

* Fix a flapper test

The following changes were made to the `Cro::WebApp` distribution:

* The `template-location` subroutine now works in a lexical fashion
  instead of being global, this is a breaking change
* Introduce the template parts mechanism to factor out data obtaining for
  common parts in templates
* Implement getting templates from the distribution resources
* Add a `parse-template` subroutine allowing to parse and compile
  a template from a `Str`
* Suppress a misleading warning during the test run
Fix parsing of HTML comments that contain `<` within the comment

The following changes were made to the `Cro` distribution:

* Make tests a bit more robust
* Improve documentation

This release was contributed to by Alexander Kiryuhin, Jonathan Worthington,
and vendethiel from [Edument](http://cro.services/training-support), together
with the following community members: Vadim Belman, Geoffrey Broadwell.

## 0.8.5

This release brings support for the `TCP_NODELAY` option and enables it by default
for TCP and TLS connections, improving latency. Meanwhile, Cro templates will now
be reloaded without a service restart if `CRO_DEV=1` is set in the environment, and
template parse error reporting is significantly improved.

The following changes were made to the `Cro::Core` distribution:

* Add support for enabling `TCP_NODELAY` by providing a `nodelay` subroutine
  updating the socket to enable the option, add a flag in `Cro::TCP` connector
  to enable it.
* Make media type parsing more lenient
* Provide a proper error message on calling the `stop` method on
  a `Cro::Service` before `start`

The following changes were made to the `Cro::TLS` distribution:

* Support `TCP_NODELAY` for TLS connections.

The following changes were made to the `Cro::HTTP` distribution:

* Add `Log::Timeline` logging in `Cro::HTTP::Client`, so request processing
  can be visualized
* Enable `TCP_NODELAY` by default
* Fix redirection to a relative URL when the initial request URL had no
  trailing `/`

The following changes were made to the `Cro::WebSocket` distribution:

* Make `web-socket` routine a multi to allow overloading it

The following changes were made to the `Cro::WebApp` distribution:

* Allow hot reload of compiled templates when the `CRO_DEV` environment
  variable is set
* Add `Log::Timeline` logging for template compilation and rendering
* Improve parse error in templates
* Allow optional dot after an array sigil in iteration (e.g. `<@.foo>`)
* Add the `:test` parameter to the `template-location` routine, allowing
  one to setup filtering of files taken as templates
* Provide a preliminary API for making a custom template repository. Expose
  the `Cro::WebApp::Template::Repository` role to be implemented.

The following changes were made to the `Cro::HTTP::Test` distribution:

* Add semantic test subs `is-ok`, `is-no-content`, `is-bad-request`,
  `is-unauthorized`, `is-forbidden`, `is-not-found`, `is-method-not-allowed`,
  `is-conflict` and `is-unprocessable-entity`

The following changes were made to the `Cro` distribution:

* Change the order of questions asked during `cro stub` invocation,
  making deciding on HTTPS usage optional depending on the HTTP versions
  specified
* Properly warn a user during a `cro run` invocation if no `.cro.yml` configuration
  file was found in the current directory tree



## 0.8.4

This release brings lots of small improvements and plenty of bug fixes. Of
note, the WebSocket client received a lot of reliability fixes, and the HTTP
client gained support for proxies, automatically honoring the `HTTP_PROXY` and
`HTTPS_PROXY` environment variables. For those building HTTP services, a new
`around` feature in the router allows for easier lifting out of error handling
across all request handlers (and probably a few more interesting things that
we didn't think of yet). No compatibility issues are foreseen.

The following changes were made to the `Cro::Core` distribution:

* Add `Cro::UnhandledErrorReporter` to provide user control over the reporting
  of unhandled errors
* Provide a means to give more context when there is a problem serializing a
  message body
* Remove a workaround for a long-fixed Rakudo bug with the `CLOSE` phaser

The following changes were made to the `Cro::TLS` distribution:

* Add a certificate regeneration script and update the certificates used by
  the tests

The following changes were made to the `Cro::HTTP` distribution:

* `Cro::HTTP::Client` now has a `user-agent` option for specifying the user
  agent, which is more convenient than setting it via the headers mechanism.
  Furthermore, a default `User-agent` header with the value `Cro` is now set.
* Decode `+` characters in query strings to spaces. This isn't part of the URI spec,
  but is a widely supported extension for query strings.
* Support the `identity` transfer encoding
* Handle the `:authority` pseudo-header in HTTP/2, mapping it to the `Host`
  header
* Simplify the `SameSite` cookie processing code
* Introduce the `around` router function, which enables installation of a
  wrapper around all of a `route` block's handlers
* Give `Cro::HTTP::Body::WWWFormUrlEncoded` `keys` and `values` methods to
  make it behave a bit more like a standard hash, as well as a rather more
  useful `gist` output
* Make `Cro::HTTP::Client` honor the `HTTP_PROXY` and `HTTPS_PROXY` environment
  variables, as well as providing a means to set proxy servers to use at the
  time the client is constructed
* Improve error reporting then a response body cannot be serialized; the type
  of the body and the request URI that was being processed are now reported
* Fix upgraded connections sometimes not being closed when the body ends
* Ensure body streams are terminated on all kinds of connection termination
  (this issue was most commonly observed with WebSocket connections)

The following changes were made to the `Cro::WebSocket` distribution:

* Honor override of `Sec-WebSocket-Protocol` header
* Fix a deadlock that could occur in the client when a ping was received
  while a message was being sent
* Avoid a possible race and exception when a ping times out in the client
* Ensure all outstanding client-sent pings fail upon connection close, to
  avoid a hang in any code awaiting them
* Make handling of unexpected connection close more consistent in the client
* Make sure the close message is consistently set correctly in the client
* Ensure that all kinds of serialization failure are conveyed back to the
  client `send` caller, fixing a potential hang when serialization failed in
  certain ways
* Make sure tests can run reliably in parallel
* Assorted small code quality improvements

The following changes were made to the `Cro::WebApp` distribution:

* The `Date` and `DateTime` types may now be used on form field attributes,
  and imply the `date` and `datetime-local` control types respectively
* Give generated forms a name, otherwise multi-select lists refuse to display
  the selected items in Firefox
* Fix loss of current value with some control types in forms
* In templates, support `<@$foo>` and `<@$foo.bar>` for iterating the
  contents of a variable
* Add a direct dependency on `OO::Monitors`

The following changes were made to the `Cro` distribution:

* Allow specification of the host for `cro run` and `cro trace` through a
  `--host` option
* Handle IPv6 literals in the URL format to `cro web`
* Add documentation for all new features
* Clarify how base-uri is used in the HTTP client documentation
* Fix assorted errors in the `Cro::WebApp::Form` documentation
* Fix an example in the SPA tutorial so that it doesn't hang
* Fix link to the Cro site in the README

This release was contributed to by Alexander Kiryuhin, Jonathan Worthington,
and vendethiel from [Edument](http://cro.services/training-support), together
with the following community members: Alastair Douglas, Elizabeth Mattijsen,
Geoffrey Broadwell, Jeremy Studer, Joelle Maslak, Jonathan Stowe, Lukas Valle,
Patrick Böker, and Stefan Seifert.

## 0.8.3

This release brings a major new feature in `Cro::WebApp`: forms, which takes
much of the tedium out of gathering data using forms. It also contains
various fixes to HTTP/2 and WebSocket support, significant performance
improvements for WebSockets, a range of new features relating to templates,
and assorted smaller new features, fixes, and documentation improvements.

The following changes were made to the `Cro::Core` distribution:

* Make `Cro::Uri.parse` and related methods respect subclassing

The following changes were made to the `Cro::HTTP` distribution:

* Emit a HTTP/2 request or response object as soon as we have the
  headers, rather than waiting for the body. This brings it in line
  with how things work for HTTP/1, and also resolves issues where a
  hang could occur due to the `await` of the response never completing
  if there was an error while receiving the body.
* Translate `host` header to `:authority` in HTTP/2 requests; some
  servers mandate this
* Make sure that the trace output reports HTTP/2 when it is being used
* Give `Cro::Uri::HTTP` a way to add query string arguments, taking care
  of the encoding of them
* Add a `query` option to the request methods in `Cro::HTTP::Client`, to
  make it easy to form a query string
* Ensure that basic authentication adds a `WWW-Authenticate` header on
  missing or failed authorization, and provide a way to set the realm
* Fix `Cro::HTTP::Auth::Basic` in the case it was meant to update an
  existing session, not create one by itself
* Fix a test that tried to use port 8080, which is commonly in use
* Add more declarator docs, for better in-IDE documentation support
* Assorted small code quality improvements 

The following changes were made to the `Cro::WebSocket` distribution:

* Fix mishandling of 2-byte extended payload length
* Speed up payload masking by a factor of 200x
* Simplify and improve performance of the WebSocket frame parser, up
  to around 4x faster
* Simplify and improve performance of the WebSocket frame serializer
  by around 5-10%
* Clean up logic in the message parser

The following changes were made to the `Cro::WebApp` distribution:

* Add `Cro::WebApp::Form`, a mechanism for working with forms in web
  applications.
* Implement named arguments and parameters in the template subs and macros
  (including the `:$foo`, `:foo` and `:!foo` forms)
* Implement defaults on both positional and named arguments
* Add `True` and `False` terms, which can be used as template arguments
* Allow use of `<?$foo.bar>...</?>` in templates; this previously had to
  be written as `<?{ $foo.bar }>...</?>`
* Don't blow up on `<.foo>` when it is dereferencing a hash and the hash
  key is missing; now it evaluates to `Nil`
* Fixed transitive `<:use ...>` of templates
* Implement support for template libraries, meaning that one can provide
  libraries of templates through the module ecosystem

The following changes were made to the `Cro` distribution:

* Document the new `Cro::HTTP::Client` `query` option
* Fix incorrect trailing `/` on an example in the HTTP router documentation
* Correct documentation about HTTP basic authentication support
* Bring the `Cro::WebApp::Template` documentation up to date with all new
  features
* Add documentation for `Cro::WebApp::Form`

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington
from [Edument](http://cro.services/training-support), as well as Geoffrey
Broadwell (who is to thank for the numerous `Cro::WebSocket` improvements).

## 0.8.2

This release contains a number of small fixes and improvements, as well as
adding documentation comments to the most commonly used parts of Cro.

The following changes were made to the `Cro::Core` distribution:

* Provide an `encode-percents` function that is optionally exported by
  `Cro::Uri` when the `:encode-percents` tag is used
* Directly cover the `decode-percents` function in `Cro::Uri` in the
  tests
* Add documentation comments to various types and routines

The following changes were made to the `Cro::HTTP` distribution:

* Fix a memory leak in the HTTP/2 frame parser when using more recent Rakudo
  versions; the parser accidentally relied on an optimizer bug, which was fixed
  in Rakudo
* Update the default TLS cipher list, restoring an SSL Labs rating of "A" out
  of the box
* Add support for the `SameSite` cookie directive
* No longer buffer the logs written by `Cro::HTTP::Log::File` by default; this
  avoids delayed or lost log output when there is not a TTY attached to the
  service
* Add documentation comments to various types and routines

The following changes were made to the `Cro::WebApp` distribution:

* Implement template conditionals directly using variables, like
  `<?$foo>...</?>` and `<!$foo>...</!>`
* Support all of the Perl 6 string comparison operators
* Add documentation comments to various types and routines

The following changes were made to the `Cro` distribution:

* Don't hardcode the name `perl6` for the executable, since that is both
  unportable and won't work well with those using a `raku` executable
* Suggest next steps in the getting started documentation
* Document the new `encode-percents` function in `Cro::Uri`
* Various typo fixes

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington
from [Edument](http://cro.services/training-support), together with the
following community members: AnaTofuZ, Elizabeth Mattijsen, James Raspass,
Jeremy Studer, Nick Logan, Patrick Böker.

## 0.8.1

This release brings a new distribution, `Cro::WebApp`, which is aimed at those
who wish to use Cro to build server-side web applications that render dynamic
content server-side (as opposed to Single Page Applications, where the backend
consists almost entirely of a HTTP API called by a JavaScript application that
runs in the browser). The distribution provides `Cro::WebApp::Template`, which
is a templating engine that integrates neatly with Cro. We already have been
using this successfully in production at Edument for many months.

Another interesting change in this release is integration with `Log::Timeline`,
which allows visualization of Cro HTTP requests using [Comma IDE](https://commaide.com/) (this feature
is available in Comma Complete from 2019.5, and will be included in the Comma
Community release 2019.7). The request visualization allows one to better
understand the time taken in the request pipeline, as well as see parallel
processing of requests. Further, this can be seen alongside any other
`Log::Timeline` logging you place into your application.

Besides that, this release has numerous other bug fixes and improvements.
There are no intended compatibility breaks with Cro 0.8.0.

The following changes were made to the `Cro::Core` distribution:

* Ensure that the connection manager terminates all connection
  pipelines when the server is stopped; previously it did not keep
  track of the subscriptions properly

The following changes were made to the `Cro::HTTP` distribution:

* Support adding cookies directly into `Cro::HTTP::CookieJar`
* Add a `static-resource` response function, for serving content out of
  `%?RESOURCES`
* Integrate `Log::Timeline` to provide insight into Cro HTTP pipelines
* Fix a problem with handling of `mutlipart/form-data` bodies exposed
  by using them with OpenAPI validation
* Don't leak top-level global symbols out of `Cro::HTTP::Cookie`; expose
  things with qualified names or as lexical exports instead
* Tolerate missing spaces in cookie headers; some servers have bugs that
  produce such malformed cookie headers
* Export route verbs like `get` and `put` as `multi` candidates, so we don't
  hide the `put` built-in, which may be used for debugging output
* Correctly report which response function was used outside of a
  `route` block
* Support latest version of `JSON::Fast`
* Fix router tests on Windows
* Fix a test that could fail in the absence of ALPN support
* Fix possible issues if running tests in parallel
* Eliminate use of `v6.d.PREVIEW`

The following changes were made to the `Cro::WebSocket` distribution:

* Fix some cases where connection closed was not conveyed properly
* Improve connection closed error reporting
* Ensure that sending an unserializable value does not result in a silent
  failure
* When reporting a crash in a WebSocket handler, note that's where it came
  from
* Code cleanup in WebSocket client
* Fix accidental reliance on a Rakudo optimizer bug in the WebSocket
  frame parser
* Add tests to cover `wss` with a custom CA

The following changes were made to the `Cro` distribution:

* Make the runner's file watching more robust
* Document faking `peer-host` and `peer-port` in tests
* Document directly adding to the cookie jar
* Document `Cro::HTTP::Request`'s `connection` method
* Document `Cro::MediaType`
* Note the need for a `use` statement in body parser and serializer examples
* Assorted typo fixes in the documentation

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington
from [Edument](http://cro.services/training-support), together with the
following community members: Clifton Wood, Elizabeth Mattijsen, Itsuki Toyota,
Martin Barth, Olivier Mengué, Patrick Böker.

## 0.8.0

This release introduces a backwards-incompatible change to the HTTP
router's middleware semantics, the new behavior resolving a common
point of confusion when dealing with authorization middleware.
The release also contains many other bug fixes and tweaks.

Before this release, middleware applied with `before` and `after`
ran once a route was matched and after a request was processed by a
matched route. This made it impossible to apply authentication
middleware without an extra level of `route`/`delegate`, since the
authentication and authorization is handled as part of route matching.

The previous behavior (applying middleware only to a route that has been
matched) is preserved and renamed to `before-matched` and `after-matched`.
Therefore, any code can be adapted by replacing calls to `before` to
use `before-matched`, and replacing calls to `after` to `after-matched`.

The new `before` and `after`-applied middleware semantics result in a
`route` block returning the Cro composition of the `before` components,
followed by the route handler, followed by the `after` components - much
as happens when applying middleware at the server level.

Further, all middleware application in a `route` block will apply to all
routes inside of the block, not just those located textually after it as
was the case before. This is trivially the case for `before` and `after`
(there's no other way it could be, given the new semantics), but is also
now the case with `before-matched` and `after-matched`

The following changes were made to the `Cro::HTTP` distribution:

* New middleware semantics, as described above.
* Fix handling of cookies with the `expires` property defined instead of
  `max-age`.
* Properly set a `Cro::HTTP::Request` object to the `request` attribute of
  a HTTP response received with `Cro::HTTP::Client`. Also add a `request`
  method to the client exception types as a shortcut for getting the request
  object that resulted in an error.
* Add new `uri` method to `Cro::HTTP::Request` which gives the full
  request URI. This is especially useful if the HTTP client followed a
  redirect and one wishes to know exactly what URI was fetched in the end.
* Fix an exception in `Cro::HTTP2::FrameParser` related to data decoding
  of HTTP/2.0 frame.
* Fix a bug that led to lowercasing of cookie values in HTTP/2.0. This in
  turn fixes usage of `Cro::HTTP::Session::InMemory` under HTTP/2.0.
* Indicate with an exception situation when HTTP/2.0 client/server
  sends RST frame of stream that Cro server/client does not know about.
* Fix cookie setting path.
* Make session cookie be always set to `/` path, so now Cro session
  mechanism correctly updates cookie with a new session after the old
  one expires.
* Use the `Authorization` header name instead of `Auth` in
  `Cro::HTTP::Auth::WebToken::Bearer`.
* Fix compliance with the HTTP spec on the host header: now we append
  `Host` header when non-standard HTTP port (not 80 nor 443) is used.
* Force use of Perl 6.d semantics in the HTTP client, which avoids
  various ways that it might end up working slowly due to eating too
  many real threads.
* When a route fails to match with 400 or 401, and another route fails
  to match with a 405, prefer the 400 or 401 error.

The following changes were made to the `Cro::WebSocket` distribution:

* Do a `note` of unhandled exceptions in WebSocket handlers,  instead
  of silently losing them.

The following changes were made to the `Cro` distribution:

* Document new router middleware semantics of `Cro::HTTP::Router`.
* Make `Cro::Tools::Template::HTTPService` easier to inherit by
  changing `$include-websocket` specialised parameter into more
  generic `%options` one.
* Fix indentation-related warning on Cro installation.
* Add a multipart/form-data body handling example on
  `Cro::HTTP::Router` documentation page.
* Add document on structuring larger services/apps with Cro.
* Document `request` property of HTTP client exception.
* Document using `CRO_TRACE` with the HTTP client.
* Document `uri` method of `Cro::HTTP::Request`.
* Fix a long-standing issue with instant restart of Cro service right
  after its start with `cro run`.
* Issues with `.cro.yml` file are now reported to user when `cro
  run` is being used, instead of too generic `service cannot be
  started` message.
* Consider case when `.cro.yml` file is created, but its content is
  not yet written, which could lead to an exception before.
* Better document `Cro::WebSocket::Client`.
* Indicate cause of a service restart to the user to make it easier
  to discover which files to ignore if getting unwanted restarts.

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington
from [Edument](http://cro.services/training-support), together with the
following community members: Xliff, lukasvalle, Rod Taylor, Lance Wicks, Nick Logan.

## 0.7.6

This release contains a number of minor new features (better support for
working with the less commonly used HTTP methods, and an `ignore` section in
the `.cro.yml` file). It also contains numerous fixes and tweaks, as well as
some documentation improvements.

The following changes were made to the `Cro::Core` distribution:

* Allow a trailing `;` in media types
* Fix media type parse error on many-dot subtype

The following changes were made to the `Cro::HTTP` distribution:

* Set default ciphers to Moz. Modern Compatibility
* Do not provide a default randomized cookie name for the persistent session
  role, and instead give an error if the user does not set `cookie-name`. It's
  useless to keep sessions in a database if the cookie name changes on every
  application restart, but providing a hardcoded default is a platform
  fingerprinting risk. Making the user specify a cookie name is thus a better
  way forward.
* Fix WWWUrlEncode body parser applicability test to use `Cro::MediaType` and
  so check more robustly (it used to do a string match on the header, and so
  would get confused by a `charset` parameter).
* Fix `static` mime type handling on serving index files
* Use `original-target` in `Cro::HTTP::Log::File`, so that delegated routes
  will produce the full request target in the logs
* Provide `allowed-methods` on `Cro::HTTP::Server` in order to set the HTTP
  methods that will be accepted
* `Cro::HTTP::Router` now exports a `http` sub, providing a more convenient
  way to write routes for some of the less widely used HTTP methods (or for
  implementing protocols based on HTTP)

The following changes were made to the `Cro::WebSocket` distribution:

* Don't force the `ca` argument to be passed in order to use `wss://` in
  `Cro::WebSocket::Client`
* Force HTTP/1.1 use in `Cro::WebSocket::Client` (connecting to a secure
  endpoint hosted by a server supporting HTTP/2.0 could upgrade and then find
  itself unable to speak the WebSocket protocol, which is tied to HTTP/1.1)
* Fix various issues with URI handling in `Cro::WebSocket::Client`
* Provide more detailed trace output for WebSocket frames and messages

The following changes were made to the `Cro` distribution:

* Remove `bin/cro` from the `provides` section of `META6.json`
* Implement support for the `env` section in the `.cro.yml` file, so that
  additional environment variables can be provided at development time
* Implement an `ignore` section in the `.cro.yml` file to ignore certain paths
  from being watched to decide to make a service restart
* Fix dependencies of a generated ZeroMQ project
* Clarify deployment documentation
* Document new `ignore` support in `.cro.yml`
* Document `allowed-methods` HTTP server option
* Document new `http` sub for custom request methods in router
* Text tweaks to HTTP client introduction text
* Document custom HTTP methods in the client
* Add a code example of .body in HTTP client docs
* Various typo fixes in the documentation

This release was contributed to by Alexander Kiryuhin and Jonathan Worthington
from [Edument](http://cro.services/training-support), together with the
following community members: cono, FCO, Fritz Zaucker, Lance Wicks, Moritz
Lenz, Nick Logan.

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
* Avoid trace output throwing exceptions on Windows

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
