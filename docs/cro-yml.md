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
* The key `entrypoint`, which is the Perl 6 source file that should be run to
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
    entrypoint: service.p6
