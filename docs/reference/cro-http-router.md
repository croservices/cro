# Cro::HTTP::Router

In Cro, an HTTP application is a `Cro::Transform` turning `Cro::HTTP::Request`
objects into `Cro::HTTP::Response` objects. The `Cro::HTTP::Router` module
provides a declarative way to map HTTP requests to appropriate handlers, which
in turn produce responses.

## URI segment matching

The router uses Raku signatures to match URLs and extract segments from them.
A set of routes are placed in a `route` block. The empty signature corresponds
to `/`.

```
my $app = route {
    # GET /
    get -> {
        ...
    }
}
```

Literal URL segments are expressed as literals:

```
my $app = route {
    # GET /catalogue
    get -> 'catalogue' {
        ...
    }

    # GET /catalogue/products
    get -> 'catalogue', 'products' {
        ...
    }        
}
```

Positional variables are used to capture URI segments. By default, they will be
provided as a `Str`, and so placing a `Str` type constraint on the parameter is
equivalent to leaving it off.

Placing an `Int` type constraint on the parameter means the route will only
match if the segment can be parsed as an integer (`/^ '-'? \d+ $/`); UInt is
recognized and handled in the same way, but only allows positive integers. It
is also possible to use `int8`, `uint8`, `int16`, `uint16`, `int32`, `uint32`,
`int64`, and `uint64`, which work like `Int` or `UInt` but perform range
validation.

```
my $app = route {
    # GET /catalogue/products/42
    get -> 'catalogue', 'products', uint32 $id {
        ...
    }

    # GET /catalogue/search/saussages
    get -> 'catalogue', 'search', $term {
        ...
    }
}
```

It is also possible to use `where` clauses or `subset` types, in order to do
more powerful matching.

```
my $app = route {
    my subset UUIDv4 of Str where /^
        <[0..9a..f]> ** 12
        4 <[0..9a..f]> ** 3
        <[89ab]> <[0..9a..f]> ** 15
        $/;

    get -> 'user-log', UUIDv4 $id {
        ...
    }
}
```

In the case of a `subset` type, the underlying nominal type must be `Str` or
`Int` (or `Any` or `Mu`, which are treated equivalent to `Str`). All other
types on URL segments are disallowed.

A variable segment may be made optional, in which case the route will match
even if the segment is absent.

```
my $app = route {
    # GET /products/by-tag
    # GET /products/by-tag/sparkly
    get -> 'products', 'by-tag', $tag-name? {
        ...
    }
}
```

A slurpy positional can be used in order to capture all trailing segments.

```
route {
    get -> 'catalogue', 'tree', *@path {
        ...
    }
}
```

Unlike some routing engines, `Cro::HTTP::Router` does not purely consider the
routes based upon their order of declaration. The rules are as follows:

* Longest literal initial segments win. For example, for a request to `GET
  /category/search`, the route `get -> 'category', 'search' { }` would win over
  `get -> 'category', $name { }` no matter what order they were declared in.
* Declared segments always beat slurpy segments. For example, given `GET
  /tree/describe`, the route `get -> 'tree', $operation { }` would win over
  `get -> 'tree', *@path { }` no matter what order they were declared in.
* Routes with segments which are constrained in some way will always be tried
  ahead of those which are not. For example, `get -> 'product', ISBN13 $i { }`
  would be tried ahead of `get -> 'product', Str $query { }`, and chosen if it
  matched. For the purposes of the Cro router, `Int` is constrained compared
  to `Str`. Routes that are constrained in any way are considered "equal", and
  will be tested in the order they were written in source.

In the event no route matches on segments, the router will produce a HTTP 404
Not Found response.

## Request methods

Besides `get`, the router exports subs for the HTTP methods `post`, `put`,
`delete`, and `patch`.

```
my $app = route {
    # POST /catalogue/products
    post -> 'catalogue', 'products' {
        ...
    }

    # PUT /catalogue/products/42
    post -> 'catalogue', 'products', uint32 $id {
        ...
    }

    # DELETE /catalogue/products/42
    delete -> 'catalogue', 'products', uint32 $id {
        ...
    }

    # PATCH /catalogue/products/42
    patch -> 'catalogue', 'products', uint32 $id {
        ...
    }
}
```

These are all short for the `http` sub:

```
my $app = route {
    # POST /catalogue/products
    http 'POST', -> 'catalogue', 'products' {
        ...
    }

    # PUT /catalogue/products/42
    http 'PUT', -> 'catalogue', 'products', uint32 $id {
        ...
    }

    ...
}
```

Except that it may be used with any HTTP request method:

```
my $app = route {
    http 'LINK', -> $id {
        ...
    }
    http 'UNLINK', -> $id {
        ...
    }
}
```

However, **these will not work** unless the `Cro::HTTP::Server` being used to
host the application is configured to accept them using its `allowed-methods`
constructor parameter.

If a route matches on segments, but not on the HTTP method (for example, a
`PUT` was performed, but the only routes matching are for `GET` and `POST`),
the result will be a HTTP 405 Method Not Allowed response.

## Query string, headers, and cookies

Named parameters in a route signature can be used to unpack and constrain the
route match on additional aspects of the request. By default, values are taken
from the query string, however traits can be applied to have them use data
from other sources. Note that named parameters in Raku are optional by default;
if the query string parameter is required, then it should be marked as such.

```
my $app = route {
    # Must have a search term in the query string.
    get -> 'search', :$term! {
        ...
    }

    # Mininum and maximum price filters are optional; sourced from the query
    # string.
    get -> 'category', $category-name, :$min-price, :$max-price {
        ...
    }

    # Must have a term in the query string (the `is query` trait here is purely
    # for documentation purposes).
    get -> 'search', :$term! is query {
        ...
    }
}
```

As with URL segments, the `Int`, `UInt`, `int64`, `uint64`, `int32`, `uint32`,
`int16`, `uint16`, `int8` and `uint8` types may be used to parse parameters as
an integer and range-check them. Further, `subset` types based on `Int`, `UInt`,
and `Str` are also allowed.

Sometimes, multiple values may be provided for a given name in the query
string. In these cases, if there is no type constraint, then an object of type
`Cro::HTTP::MultiValue` will be passed. This object inherits from `List`, and
so can be iterated to get the values. It also does the `Stringy` role, and
stringifies to the various values joined by a comma. To rule this out, a `Str`
constraint may be applied, which will refuse to accept the request if there
are multiple values. To explicitly allow multiple values, use the `@` sigil
(note that this may not be used in conjunction with other type constraints).
This will also happily accept zero or one values, giving an empty and
1-element list respectively. Use a `where` clause to further constrain this.

```
my $app = route {
    # Require a single city to search in, and allow multiple selection of
    # interesting numbers of rooms.
    get -> 'apartments', Str :$city!, :@rooms {
        ...
    }
}
```

To get all query string data, a hash named parameter may be used (optionally
with the `is query` trait):

```
my $app = route {
    # Get a hash of all query string parameters
    get -> 'search', 'advanced', :%params {
        ...
    }
}
```

Both cookies and headers may also be unpacked into named parameters, using the
`is cookie` and `is header` traits. The same rules about multiple values are
taken into account for headers (cookies may not have duplicate values for per
name). The `is header` trait is the only one that functions in a case-insensitive
manner, since request headers are defined as case-insensitive.

```
my $app = route {
    # Gets the accept header, if there is one.
    get -> 'article', $name, :$accept is header {
        ...
    }

    # Gets the super-sneaky-tracking-id cookie; does not match if there
    # is no such cookie (since it's marked required).
    get -> 'viral', $meme, :$super-sneaky-tracking-id! is cookie {
        ...
    }

    # Gets all the cookies and all the headers in hashes.
    get -> 'dump', :%cookies is cookie, :%headers is header {
        ...
    }
}
```

Named parameters do not take part in the initial routing of a request, which is
done using the route segments. However, they may tie-break between multiple
possible routes that match the same route segments. In this case, they will be
tried in the order that they are written in the source, with the exception that
route handlers without any named parameters will be tried last. This means it
is possible to differentiate handlers by required named parameters.

```
my $app = route {
    # /search?term=mountains&images=true
    get -> search, :$term!, :$images where 'true' {
        ...
    }

    # /search?term=mountains
    get -> search, :$term! {
        ...
    }
}
```

If there is at least one route handler that matches on the URL segments, but
all of the candidates fail to match on conditions expressed using named
parameters, then the router will produce a HTTP 400 Bad Request response.

## Accessing the Cro::HTTP::Request instance

Inside of a request handler, the `request` term may be used to obtain the
`Cro::HTTP::Request` object that corresponds to the current request. In many
request handlers, this will not be required, since signatures allow for
unpacking the most common forms of request information. If the full set of
request headers were needed in their original order, however, they could be
accessed using `request`.

```
my $app = route {
    get -> {
        say "Request headers:";
        for request.headers {
            say "{.name}: {.value}";
            content 'text/plain', 'Response';
        }
    }
}
```

## Request bodies

Requests will be dispatched by `Cro::HTTP::Router` as soon as the headers are
available; the request body, if any, will become available once it has arrived
over the network. The `request` term provides the `Cro::HTTP::Request` object,
which has various methods for accessing the request body (`body`, `body-text`,
and `body-blob`), all returning a `Promise`. As a convenience, the router also
exports the subs `request-body`, `request-body-text`, and `request-body-blob`,
which take a block. These routines will call the appropriate method on the
request object, `await` it, and then invoke the block with it. For example:

```
post -> 'product' {
    # Get the body produced by the body parser for a JSON request body (it
    # is deserialized automatically if the content-type of the request
    # indicates JSON).
    request-body -> %json-object {
        # Save it, and then...
        created 'product/42', 'application/json', %json-object;
    }
}

post -> 'photos', 'add' {
    # Given a HTML form using enctype="multipart/form-data", with a text
    # input "title" and an file upload input "photo", get the title and
    # uploaded file's filename and contents.
    request-body -> (:$title, :$photo, *%rest) {
        my $file-name = $photo.filename;
        my $file-content = $photo.body-blob;
        # Process the upload
    }
}

put -> 'product', $id, 'description' {
    # Get the body as text (assumes the client set the body to some text; note
    # this is not something a web browser form would do).
    request-body-text -> $description {
        # Save it; produce no content response
    }
}

put -> 'product', $id, 'image', $filename {
    # Get the body as a binary blob (again, this assumes that a client send a
    # request with a body that's a bunch of bytes that we want; this may happen
    # in a HTTP API, but not from a browser).
    request-body-blob -> $image {
        # Save it; produce no content
    }
}
```

The block signature may use Raku signatures in order to unpack the data that
was submitted. This is useful to, for example, unpack a JSON object:

```
post -> 'product' {
    request-body -> (:$name!, :$description!, :$price!) {
        # Do stuff here...
    }
}
```

In the event that the signature cannot be bound, an exception will be thrown
that results in a `400 Bad Request` response. This means that signatures may
be used to do basic validation of the request body also.

In the event that `request-body`, `request-body-text`, or `request-body-blob`
are passed a Pair, the key will be taken as a media type to be matched against
the `Content-type` header of the request. Any parameters on the media type will
be ignored (for example, a `Content-type` header of `text/plain; charset=UTF-8`
will only have the `text/plain` part considered). If the request does not match
the `Content-type`, then an exception will be thrown that results in a `404 Bad
Request` response.

```
post -> 'product' {
    request-body 'application/json' => -> (:$name!, :$description!, :$price!) {
        # Do stuff here...
    }
}
```

If multiple arguments are given, then they will be tried in order until one
matches, with an exception thrown that results in a `400 Bad Request` response
if none match. The arguments may be `Block`s, `Pair`s, or a mixture. This
allows switching on `Content-type` of the request body:

```
put -> 'product', $id, 'image' {
    request-body-blob
        'image/gif' => -> $gif {
            ...
        },
        'image/jpeg' => -> $jpeg {
            ...
        };
}
```

Or switching on `Content-type`, but providing a block at the end as a fallback:

```
put -> 'product', $id, 'image' {
    request-body-blob
        'image/gif' => -> $gif {
            ...
        },
        'image/jpeg' => -> $jpeg {
            ...
        },
        {
            bad-request 'text/plain', 'Only gif or jpeg allowed';
        }
}
```

If the parameter of the body block has either a type constraint, a `where`
constraint, or a sub-signature, then this will be tested to see if it matches
the body object. If it does not, then the next alternative will be tried. This
allows for pattern-matching on the structure and content of some incoming data:

```
post -> 'log' {
    request-body
        -> (:$level where 'error', :$message!) {
            # Process errors specially
        },
        -> (:$level!, :$message!) {
            # Process other levels
        };
}
```

## Adding custom request body parsers

By default, five body parsers are provided for requests:

* `Cro::HTTP::BodyParser::WWWFormUrlEncoded` - used whenever the content-type
  is `application/x-www-form-urlencoded`; parses the form data and provides it
  as an instance of `Cro::HTTP::Body::WWWFormUrlEncoded`
* `Cro::HTTP::BodyParser::MultiPartFormData` - used whenever the content-type
  is `multipart/form-data`; parses the multipart document and provides it as
  an instance of `Cro::HTTP::Body::MultiPartFormData`
* `Cro::HTTP::BodyParser::JSON` - used whenever the content-type is either
  `application-json` or anything with a `+json` suffix; parses the data using
  the `JSON::Fast` module, which returns a `Hash` or `Array`
* `Cro::HTTP::BodyParser::TextFallback` - used whenever the content-type has a
  type `text` (for example, `text/plain`, `text/html`); uses `body-text`
* `Cro::HTTP::BodyParser::BlobFallback` - used as a last resort and will match
  any message; uses `body-blob`

Cro can be extended with further body parsers, which would implement the
`Cro::HTTP::BodyParser` role. These can be added globally by passing them when
setting up `Cro::HTTP::Server`. They can also be applied within the scope of a
`route` block:

```
my $app = route {
    body-parser My::Custom::BodyParser;

    post -> 'product' {
        request-body -> My::Type $body {
        }
    }
}
```

Here, a body parser `My::Custom::BodyParser` has been used, which presumably
produces objects of type `My::Type`. This might be used from anything, from
using a YAML or XML parser up to parsing requests into application-specific
domain objects.

## Producing responses

Before calling the request handler, the router creates a `Cro::HTTP::Response`
object. The default response is 204 No Content, or 200 OK if a body is set.
This object can be accessed using the `response` term. Therefore, responses may
be produced by calling methods on the `response` term:

```
my $app = route {
    get -> 'test' {
        given response {
            .append-header('Content-type', 'text/html');
            .set-body: q:to/HTML/;
                <h1>Did you know...</h1>
                <p>
                  Aside from fingerprints, everyone has a unique tongue print
                  too. Lick to login could really be a thing.
                </p>
                HTML
        }
    }
}
```

This can be rather long-winded, so the router module also exports various
routines that take care of the most common cases of forming responses.

The `header` routine calls `response.append-header`. It can accept two strings
(name and value), a single string of the form `Name: value`, or an instance of
`Cro::HTTP::Header`.

The `content` routine takes a content type and the data that should make up
the body of the response. The data will be processed by a body serializer. The
default set of body serializers in effect allow for:

* Setting the content-type to `application/json` or any media type with the
  `+json` suffix, and provided a body that can be handled by `JSON::Fast`
* Providing a `Str` body, which will be encoded according to any `charset`
  parameter in the `content-type`
* Providing a `Blob`, which will be used as the body
* Providing a `Supply`, which will be taken to mean the body will produced
  over time; unless a `content-length` header has been set explicitly, then
  the response will be sent with the chunked transfer coding

Therefore, a simple HTML response can be written as:

```
my $app = route {
    get -> 'test' {
        content 'text/html', q:to/HTML/;
            <h1>Did you know...</h1>
            <p>
              Aside from fingerprints, everyone has a unique tongue print
              too. Lick to login could really be a thing.
            </p>
            HTML
    }
}
```

The `created` routine is used to respond to `POST` requests that create a new
resource. It results in a HTTP `201` response. It can take either:

* A single positional argument specifying the location of the created resource,
  which will be used to populate the `Location` header
* Three positional arguments. The first will be used to set the `Location`
  header; the remaining two will be passed on to the `content` routine. This
  is for convenience, saving a call to `created` followed a call to `content`.

The `redirect` routine is used for redirects. It takes a single positional
argument specifying the URL to redirect to, which it places into the `Location`
response header. By default, `redirect` will result in a HTTP `307` temporary
redirect. The `:permanent` named parameter may be used to indicate that a HTTP
`308` permanent redirect should be done instead. For documentation purposes,
it is possible to pass `:temporary`. Alternatively, `:see-other` may be used
to achieve a HTTP `303` response; this is temporary, but indicates that a `GET`
request should be performed on the target rather than preserving the original
request method.

```
my $app = route {
    get -> 'testing' {
        redirect :permanent, '/test';
    }
}
```

For a redirect response including a body, the three-argument form of the
`redirect` routine may be used; the second two arguments will be used to call
`content` (and so this is precisely equivalent to calling `content` after
`redirect`).

Further routines exist for the most common HTTP error codes. These all take
either zero arguments or two arguments; the two-argument form passes its two
arguments on to `content` after setting the status code. They are:

* `not-found`, for HTTP 404 Not Found
* `bad-request`, for HTTP 400 Bad Request
* `forbidden`, for HTTP 403 Forbidden
* `conflict`, for HTTP 409 Conflict

If the request handler evaluates to `...` (that is, the Raku syntax for stub
code), then a HTTP 510 Not Implemented response will be produced. If evaluating
the route handler produces an exception, then the exception will be passed on.
It will then typically be handled by the response serializer, which will produce
a HTTP 500 Internal Server Error response, however other middleware may be
inserted to change what happens (for example, serving custom error pages).

All other response codes are produced by explicitly setting `response.status`.

## Serving static content from files

The `static` routine is used to serve static content from a file. It sets the
content of the request body to the content of the file being served, and the
content type according to the extension of the file.

In its simplest form, `static` serves an individual file:

    get -> {
        static 'www/index.html';
    }

In its multi-argument form, it treats the first argument as a base directory,
and then slurps the remaining arguments and treats them as path segments to
append to the base directory. This is useful for serving content from a base
directory:

    get -> 'css', *@path {
        static 'css', @path;
    }

This form will never serve content outside of the base directory; a path that
tries to do `../` tricks shall not be able to escape. The base can also be
specified as an `IO::Path` object.

For either of these forms, if no file is found then a HTTP 404 response will
be served. If the path resolves to anything that is not a normal file (such as
a directory) or a file that cannot be read, then a HTTP 403 response will be
served instead.

The default set of file extension to MIME type mappings are derived from the
list provided with the Apache web server. If no mapping is found, the content
type will be set to `application/octet-stream`. To provide extras or to
override the default, pass a hash of mappings to the `mime-types` named
argument.

    get -> 'downloads', *@path {
        static 'files', @path, mime-types => {
            'foo' => 'application/x-foo'
        }
    }

To serve an index file when a directory is requested (so, for example, a
request to `content/foo/` would serve `downloads/foo/index.html`), pass the
`indexes` named argument, specifying the filenames that should be considered:

    get -> 'content', *@path {
        static 'static-data/content', @path,
            :indexes<index.html index.htm>;
    }

## Serving static content from resources

Those who wish for their web applications to be installable using standard
Raku installation tools, such as `zef`, should serve static content from the
distribution resources instead of files. First, the `resources-from` routine
must be used to associate the correct `%?RESOURCES` with the `route` block.
Then, the `resource` routine can be used to serve resources.

    my $app = route {
        resources-from %?RESOURCES;

        get -> {
            # An exact resource
            resource 'static/index.html';
        }

        get -> 'css', *@path {
            # Concatenate the css prefix with the other path parts to form
            # the resource path
            resource 'css', @path;
        }
    }

The `mime-types` and `indexes` options work as for `static`.

## Adding custom response body serializers

Custom body serializers implement the `Cro::BodySerializer` role. They can
decide when they are applicable by considering the type of the body and/or
the response headers (most typically the `content-type` header).

Body serializers can be applied when configuring `Cro::HTTP::Server`, in which
case they will be applicable to all requests. They may also be applied within
a given `route` block:

```
my $app = route {
    body-serializer Custom::Serializer::YAML;

    get -> 'userlevels' {
        content 'application/yaml', <reader moderator producer admin>;
    }
}
```

## Setting response cachability

The `cache-control` sub provides a convenient way to set the `Cache-control`
header in the HTTP response, which controls whether, and for how long, the
response may be cached. If there already is a cache control header, it will be
removed and a new one added as specified.

The `cache-control` sub may be passed the following named parameters:

* `:public` - may be stored by any cache
* `:private` - may only be stored by a single-user cache (for example, in the
  browser)
* `:no-cache` - cache entry may never be used without checking if it's still
  valid
* `:no-store` - response may never even be stored in a cache
* `:max-age(600)` - how old the content can become before the cache should
  evict it
* `:s-maxage(600)` - as for `maxage` but applies only to shared caches
* `:must-revalidate` - the response may not be used after the `max-age` has
  passed
* `:proxy-revalidate` - same as `must-revalidate` but for shared proxies
* `:no-transform` - the response must not be transformed (e.g. recompressing
  images)

It will emit a single `Cache-control` header with the options comma-separated.

A typical usage to cache image assets for up to 10 minutes in any cache would
be:

    cache-control :public, :max-age(600);

This could be used with static file serving:

    get -> 'css', *@path {
        cache-control :public, :max-age(300);
        static 'css', @path;
    }

To state a response should never be stored in a cache, it is in theory enough
to state:

    cache-control :no-store;

However, given differing interpretations by different user-agents, it is wise
to instead use:

    cache-control :no-store, :no-cache;

## Push Promises

HTTP/2.0 allows the response to include push promises. A push promise is used
to push content associated with the response to the client. For example, CSS,
JavaScript, or images needed for a page might be pushed, so as to save the
client from needing to request them as it parses the page.

The `push-promise` function provided by the router is the most convenient way
to include a push promise with the current response. The simplest approach is
to call it with the route of the resource to respond with:

```
get -> {
    push-promise '/css/main.css';
    content 'text/html', $some-content;
}
get -> 'css', *@path {
    cache-control :public, :max-age(300);
    static 'assets/css', @path;
}
```

In the case that the route is reached via an `include` or `delegate` with a
prefix, the leading `/` will be interpreted as relative the enclosing `route`
block (put another way, any prefixes will be prepended to form the URL that
is being promised).

Push promises are processed like requests; they are emitted by the HTTP/2.0
message parser, and thus will go through all middleware that a normal request
would.

By default, no headers are included in the push promise request. To include
them, pass the `headers` named parameter, with either a `Hash` or a `List` of
`Pair` (the latter form exists in case header ordering or multiple headers of
the same name are desired). To simply pass on any headers as they appear in
the request currently being processed, use `*` as the value; if the current
request doesn't have such a header, it will not be included into the push
promise.

```
get -> {
    push-promise '/js/strings.js', headers => {
        Accept-language => *
    };
    content 'text/html', $some-content;
}
```

In the case that the request currently being processed was not a HTTP/2.0
request, the `push-promise` function does nothing.

## Composing routers

For any non-trivial service, defining all of the routes and their handlers in a
single file will become difficult to manage. With `include`, it is possible to
move them out to different modules. For example, a module `OurService::Products`
could be written as follows:

```
sub product-routes() is export {
    route {
        get -> 'products' { ... }
        get -> 'products', uint32 $id { ... }
        # ...
    }
}
```

And then its routes included into a top-level routing table:

```
use OurService::Products;

my $app = route {
    get -> { ... }
    include product-routes;
}
```

This is still a little repetitive due to every route in the module having to
include `products` at the start of its routes. So, refactoring the module as:

```
sub product-routes() is export {
    route {
        get -> { ... }
        get -> uint32 $id { ... }
        # ...
    }
}
```

The URL structure could be preserved by including it with a prefix:

```
use OurService::Products;

my $app = route {
    get -> { ... }
    include products => product-routes;
}
```

Note that multiple segment bases should be passed as a list, *not* as a string
with a `/` in it (which would instead look for a URL-encoded '/' within a
segment):

```
my $app = route {
    get -> { ... }
    include <catalogue products> => product-routes;
}
```

The `include` function can accept multiple routes or pairs, so there is no need
to repetitively type `include`:

```
my $app = route {
    include products  => product-routes,
            forum     => forum-routes,
                         static-content-routes;
}
```

An `include` merges the included routes with those declared locally, meaning
that they are considered together in a "flat" manner. This applies even when
there is a prefix, meaning one can confidently factor route handlers out into
modules. Prefixes are considered just as additional literal segments up front.
A further welcome consequence of this design is that there will be no routing
performance loss from splitting route handlers over multiple files.

If the including `route` block has body parsers and body serializers, they
will be visible to the routes in the included `route` block also, making it
possible to factor out use of body parsers and serializers. Body parsers and
serializers declared by a `route`  block that is being included will be
preferred over those provided by an including `route` block.

The `include` operation can only be used to apply routes from another HTTP
router constructed using `Cro::HTTP::Router`.

## Delegating routes to another Cro::Transform

Using `Cro::HTTP::Router` isn't the only way to write a HTTP request handler.
The router can `delegate` either a specific path, or all paths below a prefix,
to any `Cro::Transform` that consumes a `Cro::HTTP::Request` and produces a
`Cro::HTTP::Response`. It is used as follows:

```
my $app = route {
    # Delegate requests to /special to MyTransform
    delegate special => MyTransform;

    # Delegate requests to /multi/part/path to AnotherTransform
    delegate <multi part path> => AnotherTransform;

    # Delegate requests to /proxy *and* everything beneath it to ProxyTransform
    delegate <proxy *> => ProxyTransform.new(%some-config);
}
```

It is possible to pass multiple pairs to a single `delegate` call, so the
examples above could be expessed as:

```
my $app = route {
    delegate special           => MyTransform,
             <multi part path> => AnotherTransform,
             <proxy *>         => ProxyTransform.new(|%some-config);
}
```

When using `delegate`, the `Cro::HTTP::Request` object will be shallow-copied,
and the copy will have the prefix stripped from its `target`; this will also
impact the return values of `path` and `path-segments`. The `original-target`,
`original-path`, and `original-path-segments` methods return the original
paths.

Body parsers declared in the `route` block will be prefixed to the request's
body parser selector before it is passed to the transform. Any body
serializers declared in the `route` block will be prefixed to the body
serializer selector of the response produced by the transform.

Since a `route { }` block makes an object that does `Cro::Transform`, it is
possible to use it with `delegate` too. This has slightly different semantics
from `include`, and due to the need to do two route dispatches will perform a
bit worse.

## Applying middleware in a route block

*Note: The semantics described here are for Cro 0.8.0 and above. Earlier
versions lacked the current `before` and `after` semantics, and instead their
`before` and `after` had the semantics now provided by `before-matched` and
`after-matched`.*

In Cro, middleware is a component in the request processing pipeline. It may
be installed at the server level (see `Cro::HTTP::Server` for more), but also
per `route` block using the `before`, `before-matched`, `after`, and
`after-matched` functions. For readers new to middleware in Cro, the
[HTTP middleware guide](/docs/reference/cro-http-middleware) gives an overview
of what middleware is, and the trade-offs between the different ways of
writing and using HTTP middleware in Cro.

The `before` function is used to have middleware applied *before* the `route`
block is processed. Similarly, `after` applies the middleware *after* the
`route` block has been processed. Therefore:

```
my $app = route {
    before SomeMiddleware;
    after SomeOtherMiddleware;
    get -> {
        content 'text/plain', 'Hello with middleware';
    }
}
```

Is equivalent to:

```
my $routes = route {
    get -> {
        content 'text/plain', 'Hello with middleware';
    }
}
my $app = Cro.compose(SomeMiddleware, $routes, SomeOtherMiddleware);
```

This is mainly useful when the middleware:

* Might influence what routes match (for example, session and authorization
  middleware)
* Should be executed whether or not any routes from the `route` block match

A `route` block which uses `before` and `after` cannot be used with `include`.
The middleware should run before matching, however before matching it's not
possible to know if one of the included `route`s would match. Use `delegate`
instead.

By contrast, `before-matched` and `after-matched` specify middleware to be
used *only when a route has been matched*. Therefore, it is possible to use
`include` on a `route` block that uses them.

Therefore, the overall process can be seen as:

```
Run any before middleware
If a route matches then
    Run applicable before-matched middleware
    Run the route handler
    Run applicable after-matched middleware
Run any after middleware
```

Both `before` and `before-matched` may be called with any `Cro::Transform` that
consumes a `Cro::HTTP::Request` and produces a `Cro::HTTP::Request`.

Both `after` and `after-matched` may be called with a `Cro::Transform` that
consumes a `Cro::HTTP::Response` and produces a `Cro::HTTP::Response`.

It is allowed to use all of the middleware addition functions multiple times
in a single route block, and the middleware will be added in the order that
it appears. 

As a convenience, the `before`, `before-matched`, `after`, and `after-matched`
functions may be passed a `Block`. This will be invoked with the
`Cro::HTTP::Request` or `Cro::HTTP::Response` object as an argument, and it can
mutate the request or response (the return value of the block is ignored). The
various response helper functions that are available inside of a route handler
are also available, so adding an extra header to the response can be achieved by:

```
after {
    header 'Strict-transport-security', 'max-age=31536000; includeSubDomains'
}
```

In some cases, it is desirable for `before` middleware to itself produce the
response. When using the block form, the `response` symbol and all functions
that aid in producing responses are available. The `before` will be considered
to have produced a response if, after it has run, the `status` of the response
has been set. For example, producing a 403 Forbidden response to all requests
not coming from the loopback interface could be achieved using:

```
before {
    forbidden unless .connection.peer-host eq '127.0.0.1' | '::1';
}
```

A `before` actually inserts two pipeline components: one that runs the block,
and one that outputs any "early" responses produced by the middleware. The
latter component is inserted as if it were introducd by an `after` immediately
after the `before`. This means that any `after` middleware specified prior to
the `before` block making the early response will be skipped over.

```
# WRONG - the first `after` will be skipped over and so never see the 403
# Forbidden
after {
    if .status == 403 && !.has-body {
        content 'text/html', '<h1>Forbidden</h1>';
    }
}
before {
    forbidden unless .request.connection.peer-host eq '127.0.0.1' | '::1';
}

# CORRECT - the `after` is placed after any early response from the `before`
# is inserted into the output pipeline, and so will add the content to the
# response, as desired.
before {
    forbidden unless .request.connection.peer-host eq '127.0.0.1' | '::1';
}
after {
    if .status == 403 && !.has-body {
        content 'text/html', '<h1>Forbidden</h1>';
    }
}
```

When `include` is used, the `before-matched` middleware of the including
`route` block will be applied ahead of any middleware in the target of the
`include`, and the `after-matched` middleware of the including `route` block
will be applied after the target of the include. Effectively, the middleware
of the including route block wraps around those of the included.

## Wrapping route handlers

The `around` function can be used at `route`-block level to wrap all handlers
within that `route` block. This could be used to provide uniform exception
handling across a set of request handlers.

```
my $application = route {
    around -> &handler {
        # Invoke the route handler
        handler();
        CATCH {
            # If any handler produces this exception...
            when Some::Domain::Exception::UpdatingOldVersion {
                # ...return a HTTP 409 Conflict response.
                conflict;
            }
        }
    }
}
```

Both `request` and `response` are available inside of an `around` handler. At
the point it is called, the handler to call and its arguments will already
have been determined. The most you can do is choose not to invoke the handler.
Unlike with `after-matched` middleware, the default mapping of unhandled
exceptions to a `500` status code will not have been performed yet, making it
a good place to factor out mapping of domain exceptions into HTTP errors.

The first `around` call will be the innermost wrapping. Wrappings from an
`include`d `route` block will be considered inner to those in the `route`
block doing the `include`. If one `around` handler throws an exception,
another handler outer to it may catch it. Unlike with middleware, `around`
handlers are not considered pipeline components.
