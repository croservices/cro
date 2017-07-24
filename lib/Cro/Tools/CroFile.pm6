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
    has Environment @.environment;
}
