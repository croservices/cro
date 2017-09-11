role Cro::Tools::LinkTemplate {
    method protocol(--> Str) { ... }

    method generate(Str $service, Str $endpoint, %options --> Str) { ... }
}
