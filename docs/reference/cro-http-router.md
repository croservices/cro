# Cro::HTTP::Router

In Cro, an HTTP application is a `Cro::Transform` turning `Cro::HTTP::Request`
objects into `Cro::HTTP::Response` objects. The `Cro::HTTP::Router` module
provides a declarative way to map HTTP requests to appropriate handlers, which
in turn produce responses.

## URI segment matching

The router uses Perl 6 signatures to match URLs and extract segments from them.
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
    # GET /catalogue/
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

Besides `get`, the HTTP methods `post`, `put`, `delete`, and `patch` may be
used.

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
}
```

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
  /catagory/search`, the route `get -> 'category', 'search' { }` would win over
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
Not Found response. If a route matches on segments, but not on the HTTP method
(for example, a `PUT` was performed but the only routes matching are for `GET`
and `POST`), then it will instead produce a HTTP 405 Method Not Allowed.

## Query string, headers, and cookies

Named parameters in a route signature can be used to unpack and constrain the
route match on additional aspects of the request. By default, values are taken
from the query string, however traits can be applied to have them use data
from other sources. Note that named parameters in Perl 6 are optional by default;
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
    get -> 'appartments', Str :$city!, :@rooms {
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
        }
    }
}
```

## Request bodies

Requests will be dispatched by `Cro::HTTP::Router` as soon as the headers are
available; the request body, if any, will become available once it has arrived
over the network. The `request` term provides the `Cro::HTTP::Request` object,
which has various methods for accessing the request body (`body`, `body-text`,
and `body-blob`), all returning a `Promise`. As a concenience, the router also
exports the subs `request-body`, `request-body-text`, and `request-body-blob`,
which take a block. These routines will call the appropriate method on the
request object, `await` it, and then invoke the block with it. For example:

```
put -> 'product', $id, 'description' {
    # Get the body as text (assumes the client set the body to some text; note
    # this is not something a web browser form would do).
    request-body-text -> $description {
        # Save it; produce no content response
    }
}

put -> 'product', $id, 'image', $filename {
    # Get the body as a binary blob.
    request-body-blob -> $image {
        # Save it; produce no content
    }
}

post -> 'product' {
    # Get the body produced by the body parser.
    request-body -> %json-object {
        # Save it, and then...
        created, 'application/json', %json-object;
    }
}
```

The block signature may use Perl 6 signatures in order to unpack the data that
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
put -> 'product', $id, 'image {
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
put -> 'product', $id, 'image {
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

Cro can be extended with further body parsers, which whould implement the
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
    get => 'test' {
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
  over time; unless a `content-length` header has been sit explicitly, then
  the response will be sent with the chunked transfer coding

Therefore, a simple HTML response can be written as:

```
my $app = route {
    get => 'test' {
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
    get => 'testing' {
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

If the request handler evluates to `...` (that is, the Perl 6 syntax for stub
code), then a HTTP 510 Not Implemented response will be produced. If evaluating
the route handler produces an exception, then the exception will be passed on.
It will then typically be handled by the response serializer, which will produce
a HTTP 500 Internal Server Error response, however other middleware may be
inserted to change what happens (for example, serving custom error pages).

All other response codes are produced by explicitly setting `response.status`.

## Serving static content

The `static` routine is used to easily serve static content. It sets the
content of the request body to the content of the file being served, and the
content type according to the extension of the file.

In its simplest form, `static` simply serves an individual file:

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
tries to do `../` tricks shall not be able to escape.

For either of these forms, if no file is found then a HTTP 404 response will
be served. If the path resolves to anything that is not a normal file (such as
a directory) or a file that cannot be read, then a HTTP 403 response will be
served instead.

The default set of file extension to MIME type mappings are derived from the
list provided with the Apache web server. If no mapping is found, the content
type will be set to `application/octet-stream`. To provide extras or to
override the default, pass a hash of mappins to the `mime-types` named
argument.

    get -> 'downloads', *@path {
        static 'files', @path, mime-types => {
            'foo' => 'application/x-foo'
        }
    }

## Adding custom response body serializers

Custom body serializers implement the `Cro::HTTP::BodySerializer` role. They
can decide when they are applicable by considering the type of the body and/or
the response headers (most typically the `content-type` header).

Body serializers can be applied when configuring `Cro:HTTP::Server`, in which
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
        cache-control :public, :maxage(300);
        static 'css', @path;
    }

To state a response should never be stored in a cache, it is in theory enough
to state:

    cache-control :no-store;

However, given differring interpretations by different user-agents, it is wise
to instead use:

    cache-control :no-store, :no-cache;

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
use OurSerivce::Products;

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
use OurSerivce::Products;

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

The `include` operation can only be used to apply routes from another HTTP
router constructed using `Cro::HTTP::Router`. An alternative is `delegate`,
which can delegate all requests with a certain prefix to anything implementing
the `Cro::Transform` role (provided, of course, it maps `Cro::HTTP::Request`s
into `Cro::HTTP::Response`s).

```
my $app = route {
    delegate 'special' => MyTransform;
    delegate <multi part path> => AnotherTransform;
}
```

Since a `route { }` block makes an object that does `Cro::Transform`, it is
possible to use it with `delegate` too. This has different semantics from
`include`; the outer `route` block will not be aware of the routes inside of
the inner one, leading to a kind of double-dispatch.
