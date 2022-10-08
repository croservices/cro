# Cro::HTTP::Log::File

This response middleware provides basic logging of requests to a file handle.
By default, it logs both successful requests (response code less than 400)
and errors (response code at least 400) to `$*OUT` (the standard out file
handle), which is likely suitable for container deployment and development.
To avoid any buffering issues delaying logs, it also defaults to flushing
after each output.

## Using Alternate File Handles

To log all requests (both success and error) to another location, pass
the `logs` parameter:

```raku
my $logger = Cro::HTTP::Log::File.new(logs => open('http.log', :a));
```

To log errors to a different file, also pass the `errors` parameter:

```raku
my $logger = Cro::HTTP::Log::File.new:
    logs => open('http.log', :a),
    errors => open('error.log', :a);
```

## Controlling flushing

To disable flushing of logs after each write, set the `flush` option
to `False`:

```raku
my $logger = Cro::HTTP::Log::File.new:
    logs => open('http.log', :a),
    flush => False;
```

## If you need something more complex

If you want logs in a different format or sent elsewhere, check in the
Raku module ecosystem to see if somebody already wrote such a module or,
failing that, implement it by writing a [custom response middleware](/docs/reference/cro-http-middleware)
and using it in place of `Cro::HTTP::Log::File`.
