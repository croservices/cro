# The Cro Development Tools

Cro includes tools to help devlopers work more efficiently. Most features are
available as both a command line tool (`cro`) and a web interface (launched
using `cro web`). It is entirely possible to use Cro without these tools. They
aim to provide some reasonable defaults, but may not be suitable for every
project.

## Running the Cro Web Interface

The Cro web interface can be started using:

    cro web

To change the port that it runs on from the default, use:

    cro web 8000

To have it bind to a host other than `localhost`, use:

    cro web 192.168.0.1:8080

## Stubbing Services

A new service can be stubbed using the `cro stub` command. The general usage
is:

    cro stub <service-type> <id> <path> ['options']

Where `service-type` is the type of service to create, `id` is the ID of the
service (to be used with other `cro` coammands), `path` is the location to
create the service, and `options` are a set of options specific to the service
type. The options are written in a simplified version of Perl 6 colonpair
syntax, where `:foo` enables an option, `:!foo` disables an option, and
`:foo<bar>` is the option `foo` with the value `bar`. For example:

    cro stub http foo services/foo ':!secure :websocket :link<bar>'

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

* **`:!secure`**: generates a HTTP service instead of a HTTPS one (`:secure`
  is the default); implies `:!http2`, since ALPN is used to negotiate whether
  to use HTTP/2
* **`:!http2`**: generates a service without HTTP 2 support
* **`:!http1`**: generates a service without HTTP 1 support
* **`:websocket`**: adds a dependency to the `Cro::WebSocket` module and adds
  a stub web socket example
* **`:link<service>`**: indicates that code to interact with the specified
  other service should be stubbed; that service must exist in some folder
  beneath the current working directroy, and have a `.cro.yml` with the
  specified service name.

## Running Services

The `cro run` command is used to run services. It automatically sets up file
watching and restarts services when there are source changes to the services
(with a debounce to handle a stampede of changes, for example due to fetching
latest changes of a running service from version control or saving many files
in an editor). To run all services (identified by searching for `.cro.yml`
files in the current working directory and its subdirectories), use:

    cro run

To run a specific service, write its name (which must appear in a `.cro.yml`
file in the current working directory or one of its subdirectories):

    cro run flashcard-backend 

It's also possible to list multiple services:

    cro run flashbard-backend users frontend

The output of the services will be displayed, prefixed with the service name.
Sending SIGINT (hitting Ctrl+C) will kill all of the services.

## Tracing Services

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

    cro trace :http;

To restrict that futher to just requests, do:

    cro trace :http :request;

Anything not starting with a `:` is taken as a service name. The order is
unimportant, so these are equivalent:

    cro trace :http flashcard-backend
    cro trace flashcard-backend :http

## Serving Static Content

Sometimes it is useful to set up a HTTP server to serve some static content.
Serve the current directory on port 8080 of localhost with:

    cro serve 8080

Or specify a directory to serve:

    cro serve 8080 static_content/

A hostname to bind to may be provided before the port also:

    cro serve 192.168.0.1:8080 static_content/
