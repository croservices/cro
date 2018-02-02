use YAMLish;

class X::Cro::Tools::CroFile::Version is Exception {
    has $.got;
    method message() {
        ".cro.yml file has unexpected version '$!got' (must be 1)"
    }
}

class X::Cro::Tools::CroFile::Missing is Exception {
    has $.field;
    has $.in;
    method message() {
        ".cro.yml file is missing required field '$!field'" ~
            ($!in ?? " in a $!in" !! "")
    }
}

class X::Cro::Tools::CroFile::Unexpected is Exception {
    has $.field;
    has $.in;
    method message() {
        ".cro.yml file has unexpected field '$!field'" ~
            ($!in ?? " in a $!in" !! "")
    }
}

class Cro::Tools::CroFile {
    class Endpoint {
        has Str $.id is required;
        has Str $.name = $!id;
        has Str $.protocol is required;
        has Str $.host-env is required;
        has Str $.port-env is required;
    }

    class Link {
        has Str $.service is required;
        has Str $.endpoint is required;
        has Str $.host-env is required;
        has Str $.port-env is required;
    }

    class Environment {
        has Str $.name is required;
        has Str $.value is required;
    }

    has Str $.id is required;
    has Str $.name = $!id;
    has Str $.entrypoint is required;
    has Endpoint @.endpoints;
    has Link @.links;
    has Environment @.env;

    # TODO Remove lock once https://github.com/Leont/yamlish/issues/19 is
    # resolved, though if it's a Rakudo bug in the end then we might need to
    # keep this workaround for longer.
    my $load-yaml-lock = Lock.new;
    method parse(Str $yaml) {
        my %conf = $load-yaml-lock.protect: { load-yaml($yaml) };
        validate(%conf);
        self.bless(
            id => %conf<id>,
            |(name => %conf<name> if %conf<name>),
            entrypoint => %conf<entrypoint>,
            endpoints => (%conf<endpoints> // ()).map({ Endpoint.new(|$_) }),
            links => (%conf<links> // ()).map({ Link.new(|$_) }),
            env => (%conf<env> // ()).map({ Environment.new(|$_) })
        )
    }

    sub validate(%conf) {
        check-fields %conf, :require<cro id entrypoint>, :allow<name endpoints links env>;
        die X::Cro::Tools::CroFile::Version.new(got => %conf<cro>) if %conf<cro> ne '1';
        for @(%conf<endpoints> // ()) {
            check-fields $_, :require<id protocol host-env port-env>, :allow['name'],
                :in<entrypoint>;
        }
        for @(%conf<links> // ()) {
            check-fields $_, :require<service endpoint host-env port-env>, :in<link>;
        }
        for @(%conf<env> // ()) {
            check-fields $_, :require<name value>, :in<env>;
        }
    }

    sub check-fields(%conf, :@require, :@allow, Str :$in) {
        for @require -> $field {
            die X::Cro::Tools::CroFile::Missing.new(:$field, :$in) unless %conf{$field};
        }
        if %conf.keys (-) (@require (+) @allow) -> $unexpected {
            die X::Cro::Tools::CroFile::Unexpected.new(field => $unexpected.keys.head, :$in);
        }
    }

    method to-yaml() {
        save-yaml {
            :cro(1), :$!id, :$!name, :$!entrypoint,
            :endpoints(@!endpoints.map({%(
                id => .id,
                name => .name,
                protocol => .protocol,
                host-env => .host-env,
                port-env => .port-env
            )})),
            :links(@!links.map({%(
                service => .service,
                endpoint => .endpoint,
                host-env => .host-env,
                port-env => .port-env
            )})),
            :env(@!env.map({%(
                name => .name,
                value => .value
            )}))
        }
    }
}
