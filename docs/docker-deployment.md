# Deploying Cro services in Docker containers

To aid deployment of Cro services using Docker, a number of base images are
provided. These all include a recent MoarVM and Rakudo release, which Cro has
been tested on. The `zef` installer is also included, to aid installation of
further dependencies during the container build.  A `Dockerfile` is generated
by `cro stub`; if not using this tool, see below for an example `Dockerfile`
that uses one of the Cro base images.

## Base images

* **`cro-core`** - includes the Cro::Core distribution; ideal when no other
  base image is applicable, but at least saves installing the `Cro::Core`
  library.
* **`cro-http`** - includes the `Cro::HTTP` distribution, which in turn
  depends on `Cro::TLS` and `Cro::Core`. Includes libraries required for TLS
  to work. Ideal for web services.
* **`cro-http-websocket`** - as for `cro-core-http`, but also includes
  the `Cro::WebSocket` distribution. Ideal for web servies that also use web
  sockets.
* **`cro-zeromq`** - includes the `Cro::ZeroMQ` distribution, which in turn
  depends on `Cro::Core`.

## Sample Dockerfile

The following `Dockerfile` depends on te `cro-http` base image, installs any
further dependencies that the service has using `zef`, and runs the service.
Note that it depends on ports, hosts, certificates, etc. being provided as
applicable from the environment.

```
FROM cro-services/cro-http:v0.7.1
RUN zef install --depsonly .
CMD perl6 service.p6
```

## Tips for deploying Cro services with Docker

These aren't specific to Cro, but are worth a mention.

* Always use a versioned base image rather than `:latest`
* Make sure logging has been added to services, and preferably set up some
  kind of log aggregation. Unless you have an arrangement in place to send
  logs to a centralized logging solution, prefer logging to STDOUT/STDERR, as
  then the logs can be introspected by `docker log`, `kubectl log`, etc.
* Prefer using a tool like Kubernetes rather than managing containers and
  configuration by hand
