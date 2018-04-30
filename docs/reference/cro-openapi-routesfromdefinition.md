# Cro::OpenAPI::RoutesFromDefinition

Takes an existing OpenAPI Document and allows straightforward implementation
of the API defined within it using the Cro libraries.

## Synopsis

```
# Implement the OpenAPI defined in schema.yaml.
my $routes = openapi 'schema.yaml'.IO, {
	# Given an operation defined like this:
	# 
	#   summary: Updates a pet in the store with form data
	#   operationId: updatePetWithForm
	#   parameters:
	#   - name: petId
	#     in: path
	#     description: ID of pet that needs to be updated
	#     required: true
	#     schema:
	#   	type: string
	#   requestBody:
	#     content:
	#   	'application/x-www-form-urlencoded':
	#   	  schema:
	#   	   properties:
	#   		  name: 
	#   			description: Updated name of the pet
	#   			type: string
	#   		  status:
	#   			description: Updated status of the pet
	#   			type: string
	#   	   required:
	#   		 - status
	#   responses:
	#     '200':
	#   	description: Pet updated.
	#   	content: 
	#   	  'application/json': {}
	#     '400':
	#   	description: Invalid input
	#   	content: 
	#   	  'application/json': {}
	#
	# We can implement it by receiving the route parameter as a positional
	# argument; other literal route segments need not be mentioned.
	operation 'updatePetWithForm', -> $id {
		# The request body will already have been validated, so just grab
		# it, perhaps using destructuring.
		request-body -> (:$name, :$status) {
			# Do something with it.
			$some-store.update-pet($id, $name, $status);

			# Respond (response automatically checked against schema too).
			content 'application/json', {};
		}
	}
}
```

The `$routes` object is a subclass of `Cro::HTTP::Router::RouteSet`, and so
can be included into a route block:

```
my $api-routes = openapi 'schema.yaml'.IO, {
	...
}
my $app = route {
	include 'api' => $api-routes;
}
```

Since it is also a `Cro::Transform`, then it may be hosted directly as the
application using `Cro::HTTP::Server`.

```
my $service = Cro::HTTP::Server:
	:host<0.0.0.0>, :port(10000),
	:application($api-routes);
```

## The openapi sub

The `openapi` sub works somewhat like `route` from `Cro::HTTP::Router`. As in
a `route` block, it is possible to:

* Use `before` and `after` to add middleware. The `before` middleware will be
  *after* the validation of a request takes place, and the `after` middleware
  will be run *before* the validation of a response takes place. This means
  that middleware can rely on processing a request that has passed validation,
  while `after` middleware can add, for example, standard headers (such as
  rate limiting) to responses.
* Use `body-parser` and `body-serializer` to specify body parsers and
  serializers. The body parsers will be put in place before validation of
  the body, to ensure deserialization works as desired.

By contrast, `get`, `put`, `post` and so forth are not valid in the context
of an `openapi` block, and using them will produce an error. Instead, the
`operation` sub should be used to specify the implementations of operations
defined by the OpenAPI document. The URI patterns to match will be taken from
the OpenAPI document, and need not be repeated. Similarly, `include` and
`delegate` are not available either (a form of `include` may be supported in
the future in order to allow for breaking up the definition of a large API
over multiple files).

The `openapi` sub may be passed a string containing an OpenAPI document in
either YAML or JSON:

```
openapi $json-doc, {
	...
}
```

Or an `IO` object pointing to a file to read the document from:

```
openapi "api.yaml".IO, {
	...
}
```

In either case, JSON will be detected by looking at the data that is read and
seeing if it starts with `{` (with leading whitespace allowed); failing that,
it will be parsed as YAML.

The `openapi` sub may be passed the following options:

* `:ignore-unimplemented` - by default, an operation in the OpenAPI document
  that does not have an implementation in the `openapi` block will result in
  an error being raised by the `openapi` sub. This is to help you understand
  when an API has not been completely implemented. Setting this option will
  cause unimplemented operations to be ignored instead.
* `:!validate-responses` - this option defaults to True, but may be set to
  `False`. If set to False, then responses will not be validated. This may be
  useful for increasing production performance, once confident the API has
  been correctly implemented.
* `:%formats` and `:%add-formats` - passed to `OpenAPI::Schema::Validate` to
  control format validation (`%add-formats` adds additional formats or
  overrides existing ones which `%formats` allows for a full replacement of
  the available formats).
* `:%document` - used to configure how the OpenAPI document itself is served.
  It defaults to `{ '/openapi.json' => 'json', '/openapi.yaml' => 'yaml' }`,
  which means that the OpenAPI specification will be served as both JSON and
  YAML on requests to `/openapi.json` and `/openapi.yaml` respectively. To
  serve a format at the root of the API, pass `:document{ json => '/' }` (this
  also means it will not be served at `/openapi.json` and `/openapi.yaml` any
  longer). It is fine to register multiple paths to serve the document for a
  given format at.

All operations in the OpenAPI document should have an `operationId` in order
to be implementable. Unless configured with `:ignore-unimplemented`, such
operations will be complained about, with a note that it is not even possible
to implement them.

## The operation sub

The `operation` sub is used to specify the implementation of an operation in
the OpenAPI file. It takes a string operation ID and a block that will be run
per request to that operation.

If the string operation ID does not match an `operationId` in the OpenAPI
definition, an error will be raised.

The signature of the block may be used in order to unpack various properties
of the request. This works similarly to signatures on `get` and similar in
`Cro::HTTP::Router`, but with some differences.

* The first parameter may be a session or auth object, populated according to
  the usual `Cro::HTTP::Router` rules.

* Route parameters, from the request target, will be passed as positional
  arguments. Thus, the signature of the operation **must** be able to accept
  them, and cope with optional route parameters. An error will be given if
  the signature of any operation block is not suitable. Note that literal
  route parameters must not be mentioned, and the parameter variable names
  are not significant (the route parameters are passed in the order they
  appear in the URI).

* Query string parameters **may** be unpacked into named arguments (either
  those with no applicable source trait or those marked with `is query` will
  be considered). There is no requirement to unpack all of the query string
  parameters. However, it is an error to name one that does not exist in the
  OpenAPI document.

* Headers and cookies **may** be unpacked into named arguments (using the
  `is header` and `is cookie` parameter traits). There is no requirement to
  unpack these here, and it is allowed to unpack others not mentioned in the
  OpenAPI specification (to provide access to "standard" headers, for
  example).

Otherwise, it is just like being inside a normal `get`, `post`, etc. block as
with `Cro::HTTP::Router`. The `request` and `response` terms provide access to
the request and response objects, the `request-body` sub is available, and the
various response helpers (such as `content`) are also available.

## Automatic Validation

A request will be validated against the OpenAPI definition. The following
aspects of the request will be validated:

* Method (`GET`, `POST`, etc.) (failure to match will result in an automatic
  405 response).
* Route (path) arguments from the target URI (failure to match these will
  result in an automatic 404 response).
* Query string arguments, headers, and cookies (failure to match these will
  result in an automatic 400 response).
* The content type of the request body (failure to match this will result in
  an automatic 400 response).
* The request body. Cro has built-in support for JSON, `multipart/form-data`
  and `application/x-www-form-urlencoded` request bodies, and validation will
  work out of the box. For other body formats, a `body-parser` will be
  required, and it should produce output that can be traversed like a JSON
  data structure in order for schema validation to work. Failure to match the
  schema for the request body will result in an autoamtic 400 response.

A response will (unless response validation is disabled) be validated for:

* The status code of the response. Note that 400, 404, and 405 errors that
  are automatically produced as a result of request validation will always be
  allowed through.
* That the required headers are present and match the schema.
* The content type of the response body.
* The response body. Cro has built-in support for JSON response bodies, and
  validation will work out of the box. For other formats, a `body-serializer`
  will be needed, and the data structure to serialize should be a JSON-like
  tree of hashes/arrays so it can be validated against the schema.

Failure to validate the response indicates an implementation error. A 500
error will be returned to the client, and the error will be logged.

## Manually handling request validation errors

It may in some cases be desirable to handle request validation errors as part
of the operation implementation. Note that this does not apply to an incorrect
method or non-matching route parameters. Further, it presumes that any named
unpacks in the operation signature are liberal enough to cope with the invalid
data.

To manually handle request validation errors, pass `:allow-invalid` to the
`operation` sub. The `request-validation-error` sub can then be used in order
to check if there is a validation error. If there is, then it will be populated
with an instance of `X::Cro::OpenAPI::RoutesFromDefinition::CheckFailed`, which
is a subclass of `Exception`. It has the properties:

* `http-message` - the request that failed to parse. Same as `request` in the
  scope of a handler.
* `reason` - a string explaining the reason that validation failed

If there is no request validation error, then `Nil` is returned, meaning it can be
tested using `with` or `without`.

```
operation 'foo', :allow-invalid, -> $path-param {
	with request-validation-error() -> $error {
		content 'application/json', { :result('error'), :reason($error.reason) };
	}
	else {
		???;
		content 'application/json', { :result("ok") };
	}
}
```

## Security requirements

Enforcing security requirements involves:

* Implementing the `Cro::OpenAPI::RoutesFromDefinition::SecurityChecker` role
* Passing that using the `security` named parameter to the `openapi` function

Implementing the role requires implementing a single method, which receives the
security scheme to enforce, the HTTP request object, an array of requirements
(optional, and only applicable to OpenID) and the operation ID (also optional).
It should return `True` if the requester satisfies the security requirements,
and `False` if not.

```
role Cro::OpenAPI::RoutesFromDefinition::SecurityChecker {
    method is-allowed(OpenAPI::Model::SecurityScheme $scheme, Cro::HTTP::Request $request,
            :@requirements, :$operation-id --> Bool) { ... }
}
```

For the case of API keys, the role provides a `get-api-key($scheme, $request)`
method that will use the scheme to look up the API key from the request. It will
return a `Failure` if the is no such header, cookie, or query string parameter, or
if the scheme type is not `apiKey`.

An example implementation of the role looks like this:

```
class KeyChecker does Cro::OpenAPI::RoutesFromDefinition::SecurityChecker {
    method is-allowed(OpenAPI::Model::SecurityScheme $scheme, Cro::HTTP::Request $request --> Bool) {
        with self.get-api-key($scheme, $request) -> $key {
            if $key.starts-with('totally-legit') {
                $request.auth = MyAuthInfo.new(:$key);
                return True;
            }
        }
        return False;
    }
}
```

Which could be used like this:

```
my $application = openapi $api-doc, security => KeyChecker, {
    operation 'public', -> {
        content 'text/plain', 'public ok';
    }
    operation 'private', -> {
        content 'text/plain', 'private ok, key=' ~ request.auth.key;
    }
}
```
