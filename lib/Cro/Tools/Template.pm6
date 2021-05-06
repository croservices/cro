package Cro::Tools::Template {
    class Option is export {
        has Str $.id is required;
        has Str $.name is required;
        has Any:U $.type is required where Bool|Int|Str;
        has $.default is required where Callable|Bool|Int|Str;
        has $.skip-condition;
    }
}

role Cro::Tools::Template {
    method id(--> Str) { ... }

    method name(--> Str) { ... }

    method options(--> List) { ... }

    method get-option-errors(%options --> List) { () }

    method generate(IO::Path $where, Str $id, Str $name, %options, $generated-links, @links) { ... }
}
