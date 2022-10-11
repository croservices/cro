# Cro Template Modules

## Using template files as modules 

Template subs and macros can be factored out into other template files. For
example, given `common.crotmp` as follows:

```
<:macro layout($title)>
  <html>
    <head>
      <title><$title></title>
    </head>
    <body>
      <:body>
    </body>
  </html>
</:>

<:sub alert($message)>
  <div class="alert"><$message></div>
</:>
```

These could be imported and called as follows:

```
<:use 'common.crotmp'>
<|layout('Home')>
  <h1>Welcome!</h1>
  <&alert('We missed you!')>
</|>
```

Templates are located in the same manner as if `template` were called in the
`route` block that initiated rendering of the top-level template - that is to
say, any registered `template-location`s will be considered, and if resources
were registered as a template location those will be considered too.

## In the module ecosystem

It is also possible to create Raku distributions of Cro template subs and macros,
for reuse across multiple applications and potentially for publication in the Raku
module ecosystem. Such a library should:

1. Place one or more Cro template files in `resources`.
2. Make sure those resources are mentioned in the `META6.json`
3. Have a Raku module with an `EXPORT` sub, which is defined in terms of the
   `template-library` function exported by `Cro::WebApp::Template::Library`.

The module looks like this:

```
my %exports := template-library %?RESOURCES<foo.crotmp>, %?RESOURCES<bar.crotmp>;

sub EXPORT() {
    return %exports;
}
```

Supposing that the above code was in a module `Some::Template::Library`, they can
then be imported into another Cro template as:

```
<:use Some::Template::Library>
```
