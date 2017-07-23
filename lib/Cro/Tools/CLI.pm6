proto MAIN(|) is export {*}

multi MAIN('web') {
    !!! "web"
}

multi MAIN('stub', Str $service-type, Str $name, Str $path, *@option) {
    !!! "stub"
}

multi MAIN('run') {
    !!! 'run'
}

multi MAIN('run', *@service-name) {
    !!! 'run services'
}

multi MAIN('trace', *@service-name-or-filter) {
    !!! 'trace'
}

multi MAIN('serve', Str $directory?) {
    !!! 'serve'
}
