# The Cro Development Tools

Cro includes tools to help developers work more efficiently. Currently the tools
are available through a command line interface; in the future a web interface
will be added also. It is entirely possible to use Cro without these tools. They
aim to provide some reasonable defaults, but will not be suitable for every
project.

## Stubbing Services

A new service can be stubbed using the `cro stub` command. The general usage
is:

    cro stub <service-type> <service-id> <path> ['options']

Where `service-type` is the type of service to create, `service-id` is the ID of
the service (to be used with other `cro` commands; `service-name` is this by
default), `path` is the location to create the service, and `options` are
a set of options specific to the service type. The options are written in a
simplified version of Perl 6 colonpair syntax, where `:foo` enables an option,
`:!foo` disables an option, and `:foo<bar>` is the option `foo` with the value
`bar`. For example:

    cro stub http foo services/foo ':!secure :websocket :link<service-name>'

The stubbed services take port and certificate configuration from environment
variables, and when there are relations between services their addresses are
also injected using environment variables. This is convenient when setting up
container deployment.

### HTTP Services

The `http` service type stubs in a HTTP service, using `Cro::HTTP::Router` and
served by `Cro::HTTP::Server`. By default, it stubs a HTTPS service that will
accept HTTP/1.0, HTTP/1.1 and HTTP/2.0 requests.

    cro stub http flashcard-backend backend/flashcards

The following options are be supplied:

* `:!secure`: generates a HTTP service instead of a HTTPS one (`:secure`
  is the default); implies `:!http2`, since ALPN is used to negotiate whether
  to use HTTP/2
* `:!http2`: generates a service without HTTP 2 support
* `:!http1`: generates a service without HTTP 1 support
* `:websocket`: adds a dependency to the `Cro::WebSocket` module and adds
  a stub web socket example
* `:link<service-name>`: indicates that code to interact with the specified
  other service should be stubbed; that service must exist in some folder
  beneath the current working directory, and have a `.cro.yml` with the
  specified service name.

## Running Services

    cro run [<service-name> ...]

The `cro run` command is used to run services. It automatically sets up file
watching and restarts services when there are source changes to the services
(with a debounce to handle a stampede of changes, for example due to fetching
latest changes of a running service from version control or saving many files
in an editor). To run all services (identified by searching for `.cro.yml`
files in the current working directory and its subdirectories), use:

    cro run

To run a specific service, write its `service-name` (which must appear as a `name`
in a `.cro.yml` file in the current working directory or one of its subdirectories):

    cro run flashcard-backend 

It's also possible to list multiple services:

    cro run flashbard-backend users frontend

The output of the services will be displayed, prefixed with the `service-name`.
Sending SIGINT (hitting Ctrl+C) will kill all of the services.

## Tracing Services

    cro trace <service-name-or-filter>

The `cro trace` command is much like `cro run`, except it turns on pipeline
debugging in the services. This makes it possible to see the traffic that each
service is receiving and sending, and how it is being interpreted and affected
by middleware.

The amount of output may be slightly overwhelming, so it can be filtered by
the message type name. This is done by checking if any name component is,
case-insensitively, equal to the filter. Inclusive filters are expressed as
`:name`, and exclusive filters as `:!name`. For example, to exclude all of
the TCP message messages from the trace, do:

    cro trace :!tcp

To see only HTTP messages, do:

    cro trace :http

To restrict that further to just requests, do:

    cro trace :http :request

Anything not starting with a `:` is taken as a `service-name`. The order is
unimportant, so these are equivalent:

    cro trace :http flashcard-backend
    cro trace flashcard-backend :http

## Serving Static Content

    cro serve <host-port> [<directory>]

Sometimes it is useful to set up a HTTP server to serve some static content.
Serve the current directory on port 8080 of localhost with:

    cro serve 8080

Or specify a directory to serve:

    cro serve 8080 static_content/

An IP address to bind to may also be provided before the port number:

    cro serve 192.168.0.1:8080 static_content/
