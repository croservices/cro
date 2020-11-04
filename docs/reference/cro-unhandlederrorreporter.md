# Cro::UnhandledErrorReporter

The unhandled error reporting mechanism is used when an exception occurs and
there is nothing in place to handle it, and so it propagates to the sink of a
pipeline. In HTTP applications these errors occur at a connection or request
level, rather than affecting the service as a whole.

The default erorr reporter dumps the exception and backtrace to the standard
error stream. You may provide your own unhandled error reporter if you wish
to, for example, output the error using some kind of logging framework.

This is a process-level mechanism.

## Setting an unhandled error reporter

A `set-unhandled-error-reporter` sub is exported by the module. Call it with a
block, which will be passed an `Exception` as an argument.

```
use Cro::UnhandledErrorReporter;
set-unhandled-error-reporter -> $exception {
    note "OH NO!!!\n" ~ $exception.gist();
}
```

## Reporting an unhandled error

**Note**: This mechanism is only intended for those implementing Cro pipeline
components, and for situations where the error cannot be better communicated.

Call the `report-unhandled-error` sub, passing an `Exception`, in order to
report it using the registered handler.
