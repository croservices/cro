# The Cro Development Tools

Cro includes tools to help developers work more efficiently. Currently the tools
are available through a command line interface; in the future a web interface
will be added also. It is entirely possible to use Cro without these tools. They
aim to provide some reasonable defaults, but will not be suitable for every
project.

## Stubbing Services

A new service can be stubbed using the `cro stub` command. The general usage
is:

    cro stub <service-type> <service-id> <path> ['links-and-options']

Where

* `service-type` is the type of service to create
* `service-id` is the ID of the service (to be used with other `cro`
  commands; this will also be used as the service's default descriptive
  `name` in `.cro.yml`)
* `path` is the location to create the service
* `links-and-options` specifies links to other services that should be added
  to the stub, together with options specific to the service type

If the links and options are not specified, then they will be requested
interactively. To provide the options, place them in quotes using Raku
colonpair-like syntax, where `:foo` enables an option, `:!foo` disables an
option, and `:foo<bar>` is the option `foo` with the value `bar`. For example:

    cro stub http foo services/foo ':!secure :websocket'
    cro stub http bar services/bar ':!secure :websocket'

The stubbed services take port and certificate configuration from environment
variables, and when there are relations between services their addresses are
also injected using environment variables. This is convenient when setting up
container deployment.

Links cause the stubbed service to include code that creates some kind of
"client" that can communicate with another endpoint. These go in with the
options, having the form `:link<service-id:endpoint-id>`. The `service-id` is
the `id` field from the target `.cro.yml`, and `endpoint-id` is the `id` field
of an entry in the `endpoints` list of that `.cro.yml` file.

    cro stub http foo services/foo ':link<flash-storage:http>'

### HTTP Services

The `http` service type stubs in a HTTP service, using `Cro::HTTP::Router` and
served by `Cro::HTTP::Server`. By default, it stubs an HTTPS service that will
accept HTTP/1.0, HTTP/1.1 and HTTP/2.0 requests.

    cro stub http flashcard-backend backend/flashcards

The following options may be supplied:

* `:secure`: generates an HTTPS service instead of an HTTP one (`:!secure` is
  the default); implies `:http1 :http2` by default, using ALPN to negotiate
  whether to use HTTP/2
* `:!http2`: generates a service without HTTP 2 support
* `:!http1`: generates a service without HTTP 1 support
* `:websocket`: adds a dependency to the `Cro::WebSocket` module and adds
  a stub web socket example

## Running Services

    cro run [<service-id> ...]

The `cro run` command is used to run services. It automatically sets up file
watching and restarts services when there are source changes to the services
(with a debounce to handle a stampede of changes, for example due to fetching
latest changes of a running service from version control or saving many files
in an editor). To run all services (identified by searching for `.cro.yml`
files in the current working directory and its subdirectories), use:

    cro run

To run a specific service, write its `service-id` (which must appear as the `id`
field in a `.cro.yml` file in the current working directory or one of its
subdirectories):

    cro run flashcard-backend 

It's also possible to list multiple services:

    cro run flashbard-backend users frontend

The output of the services will be displayed, prefixed with the `service-name`.
Sending SIGINT (hitting Ctrl+C) will kill all of the services.

Ports are automatically allocated and the environment variable set per the
`.cro.yml` for the service. The host environment variable will be set to
`localhost` by default, however can be specified with the `--host` option:

    cro --host=dev-vm run

## Tracing Services

    cro trace <service-id-or-filter>

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

The `--host` option may be specified as for `cro run`:

    cro --host=dev-vm trace

## Serving Static Content

    cro serve <host-port> [<directory>]

Sometimes it is useful to set up a HTTP server to serve some static content.
Serve the current directory on port 8080 of localhost with:

    cro serve 8080

Or specify a directory to serve:

    cro serve 8080 static_content/

An IP address to bind to may also be provided before the port number:

    cro serve 192.168.0.1:8080 static_content/

## Working with service links

The `cro link` subcommand is used to manage the `links` section of `.cro.yml`
files. These describe how one Cro service uses another, resulting in the
injection of environment variables specifying the host and port where the
service can be found. In production, these would be set by a container engine
such as Kubernetes, by some kind of configuration management system, or even
just hardcoded into a wrapper script.

To add a service link, use `add`:

    cro link add <from-service-id> <to-service-id> [<to-endpoint-id>]

Where `from-service-id` is the `id` of the `.cro.yml` that whose links should
be modified, `to-service-id` is the `id` of the `.cro.yml` of the service that
will be consumed, and `to-endpoint-id` is the `id` of an endpoint in that
service's `.cro.yml`. This command will, provided there is a link template
matching the protocol of the service linked to, produce some stub code that
you can paste into your service code at the appropriate place (Cro is not so
crazy as to think it can edit your code under you!)

If `to-endpoint-id` is not specified, and the `to-service-id` service has only
one endpoint, then that one will be used by default. Otherwise, the ambiguity
will be whined about.

To regenerate the code for an existing link, do:

    cro link code <from-service-id> <to-service-id> [<to-endpoint-id>]

To remove a link, use:

    cro link rm <from-service-id> <to-service-id> [<to-endpoint-id>]

Which simply removes the entry from the `links` section of the `.cro.yml` that
is identified by `from-service-id`.
