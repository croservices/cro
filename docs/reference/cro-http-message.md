# Cro::HTTP::Message

The `Cro::HTTP::Message` role is done by both `Cro::HTTP::Request` and
`Cro::HTTP::Response`. It factors out the many aspects that requests and
responses have in common, including handling of headers and bodies. Cro
uses the same request and response classes for both client and server use
cases, which besides giving less to learn also eases the writing of HTTP
intermediaries.

## Headers

### Retrieving headers

The `headers` method gets a `List` of `Cro::HTTP::Header` objects. This gets
the headers in the order they were originally received. If multiple headers
with the same name were sent, they will have multiple entries in the list.
This is both the most precise and least convenient way to access headers.

    my @links = $resp.headers.grep(*.name.lc eq 'link').map(*.value);

When expecting a single header with a particular name, use the `header` method
to retrieve its value. If there are multiple headers of the same name, their
values will be joined by commas. The header name is matched case-insensitively.
If there is no such header, then `Nil` will be returned.

    my $content-type = $resp.header('Content-type');

To get a list of header values matching a particular name (case-insensitive),
use `header-list`. This will return an empty list if there is no header with
the specified name.

    my @links = $resp.headers('link');

The `has-header` method is useful for checking if a header is present in the
request without caring about its value; again, matching is case-insensitive.

    if $resp.has-header('expires') {
        cache($resp);
    }

### Setting headers

Headers can be added to the response object using the `append-header` method.
This can take either a `Cro::HTTP::Header` object:

    $resp.append-header(Cro::HTTP::Header.new(
        name => 'ETag',
        value => '"737060cd8c284d8af7ad3082f209582d"'
    ));

Or the header in string format, which will be parsed into name and value (this
is the slowest way due to the need for parsing):

    $resp.append-header('ETag: "737060cd8c284d8af7ad3082f209582d"');

Or by specifying the header name, which must be a `Str`, and the header value,
which can be any `Cool` type and will be coerced to a `Str`:

    $resp.append-header('ETag', '"737060cd8c284d8af7ad3082f209582d"');

### Removing headers

The `remove-header` method can be used to remove one or more headers. There
are a number of overloads. The simplest takes a `Str` containing the header
name to remove. All headers with this name, matched case-insensitively, will
be removed. The number of headers removed will be returned.

    $resp.remove-header('link');

Alternatively, a predicate may be passed; all headers that match it will be
removed. Again, the number of headers removed will be returned.

    $resp.remove-header(*.name.lc eq 'link');

Finally, a `Cro::HTTP::Header` object may be passed to remove that specific
header.

    my $header = $resp.headers.pick; # Pick a random header to remove
    $resp.remove-header($header);    # And remove it

## Content type

The `content-type` method obtains the `Content-type` header, if any, and
parses it into a `Cro::MediaType` instance. If there is no `Content-type`
header, then `Nil` is returned. If for some reason the header value is not a
valid media type then an exception will be thrown.

## Body

### Retrieving the body

Cro provides access to the message body at a range of abstraction levels,
from low-level ("give me bytes as they arrived") to high level ("automatically
parse application/json and give me an object"). Note that each of these will
"sink" the body bytes, meaning that **only one of them may be used** on a
given HTTP message.

#### As a byte stream

The `body-byte-stream` method returns a `Supply` containing the bytes making
up the message, as they are received over the network. Transfer encoding (such
as "chunked") will already have been applied, as will handling of known length
content (marked by the presence of the `Content-length` header). When the body
has been full received, then a `done` will be emitted on the `Supply`.

    react {
        whenever $resp.body-stream -> $blob {
            say "Got bytes: " ~ $blob.gist;
        }
    }

#### As a binary Blob

The `body-blob` method returns a `Promise` that is kept with all of the data
emitted on `body-byte-stream` joined into a single `Blob`.

    my Blob $bytes = await $resp.body-blob();

#### As a text Str

The `body-text` method returns a `Promise` that is kept when all of the data
emitted on the `body-body-stream` has been received and then decoded to a `Str`.

    my Str $text = await $resp.body-text();

This uses the `charset` on `Content-type` as its primary means of knowing what
encoding to use. If that is missing, but the content starts with a recognized
[BOM](https://en.wikipedia.org/wiki/Byte_order_mark), then this will be taken
as the encoding to use. Failing that, the `default-enc` named parameter will
be used, if passed:

    my Str $text = await $resp.body-text(:default-enc<latin-1>);

If it is not passed, the a heuristic will be used: if the body can be decoded
as `utf-8` then it will be deemed to be `utf-8`, and failing that it will be
decoded as `latin-1` (which can never fail as all bytes are valid, although
the result may not be meaningful).

#### As an object

Implementations of the `Cro::HTTP::BodyParser` role are used to parse a HTTP
message body into an appropriate object. Examples of what a body parser might
do include:

* Parsing the `application/x-www-form-urlencoded` and `multipart/form-data`
  request bodies, most typically used by browsers to transmit form data
* Parsing an `application/json` body using a JSON library such as `JSON::Fast`
  either in a request or a response, giving a hash/array representation of
  the data
* Parsing an `application/json` into an appropriate object using `JSON::Class`
* Parsing `text/html` using the Gumbo library to get a DOM

Cro provides a number of body parsers, which it enables by default. They can
also be provided externally.

A `Cro::HTTP::Message` has a `Cro::HTTP::BodyParserSelector`, which picks
the appropriate `Cro::HTTP::BodyParser` implementation to use. This may be
changed at any point before `body` is called. Body parser selectors can come
from a range of places:

* The `Cro::HTTP::ResponseParser` and `Cro::HTTP::RequestParser` objects
  have a default set of body parsers. They may be constructed with extra body
  parsers too. This will often be specified as part of the configuration for a
  `Cro::HTTP::Server`.
* The `Cro::HTTP::Router` can add body parsers within a certain group of
  routes.
* A `Cro::HTTP::Client` can be constructed with extra body parsers to use.

The following body parsers are provided by default for requests:

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

The final 3 body parsers are in the default set for parsing responses:

* `Cro::HTTP::BodyParser::JSON`
* `Cro::HTTP::BodyParser::TextFallback`
* `Cro::HTTP::BodyParser::BlobFallback`

### Setting the Body

The `set-body` method can be used to set the body. The `Cro::HTTP::Message`
will typically then reach either a `Cro::HTTP::ResponseSerializer` (servers)
or `Cro::HTTP::RequestSerializer` (clients), which call `body-byte-stream`. At
this point, an instance of `Cro::HTTP::BodySerializerSelector` will be used to
pick a `Cro::HTTP::BodySerializer` to use. Applications can change the selector
in order to add extra body serializers at any point before the message is
serialized to be sent over the network.

The following body serializers are in the default set for serializing requests:

* `Cro::HTTP::BodySerializer::WWWFormUrlEncoded` - used when the `content-type`
  header has been set to `application/x-www-form-urlencoded` and the body was
  set to a `List` or a `Hash`, *or* when the body is an instance of
  `Cro::HTTP::Body::WWWFormUrlEncoded`. If a `List` is provided then all of
  the list elements must be pairs. If there is no `content-type` header, it
  will be added.
* `Cro::HTTP::BodySerializer::MultiPartFormData` - used when the `content-type`
  header has been set to `application/x-www-form-urlencoded` and the body was
  set to a `List`, *or* when the body is an instance of
  `Cro::HTTP::Body::MultiPartFormData`. If a `List` is provided then all of
  the list elements must be either `Cro::HTTP::Body::MultiPartFormData::Part`
  instances or pairs (a mix of the two is allowed). Any `content-type` header
  will be removed and replaced with one containing the boundary parameter.
* `Cro::HTTP::BodySerializer::JSON` - used when the `content-type` header has
  been set to `application/json` or any media type with the `+json` suffix.
  The body will be passed to `JSON::Fast` to serialize.
* `Cro::HTTP::BodySerializer::StrFallback` - used whenever the body has been
  set to `Str`. If the `content-type` contains a `charset` parameter, it will
  be used to decide on the encoding of the string; the default will be UTF-8.
  If there is no `content-type` header then a `text/plain` one will be added.
* `Cro::HTTP::BodySerializer::BlobFallback` - used whenever the body has been
  set to a `Blob`. If there is no `content-type` header than an
  `application/octet-stream` one will be added.

All of these will set a `Content-length` header.

The default set of serializers for a response are:

* `Cro::HTTP::BodySerializer::JSON` (described above)
* `Cro::HTTP::BodySerializer::StrFallback` (described above)
* `Cro::HTTP::BodySerializer::BlobFallback` (described above)
* `Cro::HTTP::BodySerializer::SupplyFallback` - used when the body has been set
  to a `Supply`. This `Supply` must emit `Blob`s; anything else will result in
  an error. This is the only built-in body serializer that does not add a
  `content-length` header (meaning that the response serializer will use the
  chunked encoding).

---
