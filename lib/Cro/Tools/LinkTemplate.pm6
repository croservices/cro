unit package Cro::Tools;

role GeneratedLink {
    has @.use;
    has Str $.setup-code is required;
    has Str $.setup-variable is required;
}

role LinkTemplate {
    method protocol(--> Str) { ... }

    method generate(Str $service, Str $endpoint, %options --> GeneratedLink) { ... }
}
