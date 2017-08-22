# cro web frontend

The `cro web` frontend is a React.js/Redux.js application, bundled into a
single JavaScript using browserify. It is written in ES6, with babel being
used to translate it into the JavaScript browsers more widely support. The
generated bundle is committed into `../resources/`, so that `cro` users do
not need to install a JavaScript build toolchain in order to use `cro`; only
those working on the frontend need care for what is in this directory and the
setup of a build toolchain.

## Setup

1. Install Node.js and `npm`.
2. `npm install -g browserify`
3. npm install .

## Building

Just run `npm build`. The output will end up in the `resources` directory of
the enclosing application.
