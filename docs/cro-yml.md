# The .cro.yml File

## Purpose

The `.cro.yml` file is stored in the root directory of a service. It provides
some metadata about the service that is used in combination with the `cro`
development tool (both the CLI and the web version). It is intended that, if
used, the file is committed to version control.

The `.cro.yml` file is only used by the `cro` development tool. It is not
required for the correct operation of the service, and need not be included
when the service is deployed (the `.dockerignore` generated when stubbing the
service excludes it from the container).

## Basic Information

The `.cro.yml` file should be a dictionary at the top level. It must include:

* The key `cro` with a value of `1`. This will allow for versioning of the
  file as Cro evolves.
* The key `id`, followed by an ID for the service. The value may contain the
  letters A..Z and a..z, the digits 0..9, the underscore (`_`), the dash (`-`)
  and the forward slash ('/'). This will be used to identify the service when
  using the CLI (such as in `cro run service-id`).
* The key `entrypoint`, which is the Raku source file that should be run to
  start the service. It should be specified relative to the `.cro.yml` file.
  This will be used by the `cro` development tool to start the service.

It may optionally include:

* The key `name`, which provides a human-friendly name for the service. This
  will be displayed in the web UI. If not provided, the `id` will be used in
  its place.

For example:

    cro: 1
    id: flashcard-backend
    name: Flashcards Backend
    entrypoint: service.raku

## Endpoints

An endpoint is something exposed by a service for services or applications to
connect to. Most often, it's a network port. The stub services produced by Cro
do not hard-code a port number, but instead take it from an environment
variable.

Endpoints are specified as a list under the `endpoints` key. For example, a
service that accepts both HTTP and HTTPS would look as follows:

```
endpoints:
    - id: http
      name: HTTP (Insecure)
      protocol: http
      host-env: FLASHCARD_BACKEND_HTTP_HOST
      port-env: FLASHCARD_BACKEND_HTTP_PORT
    - id: https
      name: HTTP (Secure)
      protocol: https
      host-env: FLASHCARD_BACKEND_HTTPS_HOST
      port-env: FLASHCARD_BACKEND_HTTPS_PORT
```

The `id` is used to identify the endpoint in commands and when referencing it
from other services. The `name` is for display in the user interface; it is
optional and will default to the `id`. The `protocol` describes the protocol
that the endpoint speaks; this is used when stubbing code to call the service
from another service. Protocols include:

* `https` - HTTP/1.1 and/or HTTP/2.0 secure (negotiated using ALPN)
* `http` - HTTP/1.1 insecure
* `http2` - HTTP/2.0 insecure (starts HTTP/2 by prior knowledge)
* `wss` - web socket secure
* `ws` - web socket insecure
* `zeromq/rep` - ZeroMQ `REP` (generated client would be a `REQ`)
* `zeromq/pub` - ZeroMQ `PUB` (generated client would be a `SUB`)

It is allowed to write multiple protocols with a comma. This is mostly useful
when an endpoint handles both HTTP and web sockets (securely as `https,wss` or
insecurely as `http,ws`).

The `host-env` and `port-env` fields name environment variables that will be
populated with the host and port that the endpoint should be hosted on.

## Links

The `links` section describes which other Cro services this one references. It
is used for `cro run` and `cro trace` (or running/tracing the services in the
web interface) to inject environment variables indicating the host and port of
the other endpoints. The environment variables can then instead be supplied by
configuration management, Kubernetes, and so forth when deploying the service.

A `links` section might look like:

```
links:
  - service: flashcard-backend
    endpoint: https
    host-env: FLASHCARD_BACKEND_HTTPS_HOST
    port-env: FLASHCARD_BACKEND_HTTPS_PORT
  - service: users
    endpoint: https
    host-env: USERS_HTTPS_HOST
    port-env: USERS_HTTPS_PORT
```

Where `service` is the ID of the service (defined by `id` in its `.cro.yml`),
`endpoint` is the ID of the endpoint (from the target service's `.cro.yml`'s
`endpoints` section), and `env` is the environment variable specifying the
host and port in the form `host:port`.

## Environment

Services will usually need other resources, such as database connections,
addresses of non-Cro services, and (development fake) security credentials. It
may be convenient to inject these using the environment. The `env` section
provides a way to set environment variables that will be passed to the
service. This is a handy way to store development configuration and cut down
a little of the setup work needed when other developers want to get the
services running.

```
env:
  - name: FLASH_DATABASE
    value: test-database.internal:6555
  - name: JWT_SECRET
    value: my-dev-not-so-secret
```

## Controlling automatic restarts

By default, `cro run` and `cro web` will automatically restart the service
when a file changes in any directory beneath where the `.cro.yml` is located.
All hidden files and directories are ignored by default (those starting with a
`.`, for example `.precomp/` and `.git/` directories).

To add extra directories to ignore, create an `ignore` section with a list of
patterns in the `.cro.yml` file. These are processed like `.gitignore`. For
example:

```
ignore:
  - node_modules/
```
