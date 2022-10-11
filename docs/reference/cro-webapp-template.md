# Cro::WebApp::Template

Templates are typically used to render some data into HTML. The template engine
is designed with HTML in mind, and takes care to escape data as it should be
escaped in HTML. Templates are compiled, typically on first use, for efficient
rendering. The template language includes conditionals, iteration, subroutines,
modules, and a number of other features.

Templates are typically stored either as files and referenced by path, or as
resources (the latter being useful if the web application should be possible
to install as a Raku distribution, for example using `zef`).

This document covers how to produce HTTP responses by rendering templates
and how templates are located; further documents cover:

* [Template language syntax](/docs/reference/cro-webapp-template-syntax)
* [Template modules](/docs/reference/cro-webapp-template-modules) (enabling
  for re-use of template subs and macros)
* [Template parts](/docs/reference/cro-webapp-template-parts) (a mechanism
  for providing data for common page elements, such as a shopping basket
  content indicator, instead of passing them into every template rendering)

## Basic usage from a Cro route block

First, add the following `use` statement to the module containing the `route`
block that you wish to use templates in:

```
use Cro::WebApp::Template;
```

Then, to produce a rendered template as the HTTP response, call `template`,
passing the path to the template and, optionally, the data that the template
should render:

```
get -> 'product', Int $id {
    my $product = $repository.lookup-product($id);
    template 'templates/product.crotmp', $product;
}
```

This is short for:

```
get -> 'product', Int $id {
    my $product = $repository.lookup-product($id);
    content 'text/html', render-template 'templates/product.crotmp', $product;
}
```

Where `render-template` renders the template and returns the result of doing
so, and `content` is from `Cro::HTTP::Router` and sets the content type of the
response along with the body. 

While by default `template` sets a content type of `text/html`; this can be
changed by passing the `content-type` named argument:

```
get -> 'product', Int $id {
    my $product = $repository.lookup-product($id);
    template 'templates/product.crotmp', $product,
        content-type => 'text/plain';
}
```

## Template locations

Templates may be served from files on disk or from distribution resources (the
`%?RESOURCES` hash). Search locations for templates may be configured either
at a `route` block level or globally (resources only at `route`-block level).

The global search location list starts out containing the current working
directory. To add further template search locations using files, call the
`template-location` function.

```
my $app = route {
    template-location 'templates/';

    get -> {
        # Will look for templates/index.crotmp first
        template 'index.crotmp';
    }
}
```

When `template-location` is called in a `route` block, it is scoped to the
route handlers within that block and will also be considered by any `route`
blocks that we `include` into this one (but *not* those we `delegate` to).
When `template-location` is called outside of a `route` block, it adds to
the global search paths. The search order is:

1. Any `tempalate-location`s in the current `route` block, tried in the
   order they were added
2. Any `template-location`s in `route` blocks that `include` us, transitively,
   innermost first
3. Any global `template-location`s

To serve templates from resources, first the resources should be associated
with the enclosing `route` block using `resources-from %?RESOURCES` (this is
not part of the template system, but rather a general mechanism of `route`
blocks). Then, `templates-from-resources` should be called to indicate that
the resources should be considered when searching for templates.

```
my $app = route {
    resources-from %?RESOURCES;
    templates-from-resources;
    get -> {
        template 'templates/index.crotmp'
    }
}
```

Applications using resources will often have many kinds of resource, and are
likely to put templates in a directory within the resources. One can avoid having
to write the `templates/` prefix repeatedly by specifying it when calling the
`templates-from-resources` function:

```
my $app = route {
    resources-from %?RESOURCES;
    templates-from-resources prefix => 'templates';
    get -> {
        template 'index.crotmp'
    }
}
```

## Template auto-reload

Templates are compiled on first use and cached for the rest of the process
lifetime. To have them recompiled automatically on changes, set `CRO_DEV=1`
in the environment. This is useful in development for avoiding application
restarts.

## Template compilation

Sometimes it may be desirable to compile all templates in advance. Passing
`:compile-all` to the `template-location` function will immediately compile
all of the templates and die if there are any errors. This could be put into
a test case:

```
use Cro::WebApp::Template;
use Test;

lives-ok { template-location 'templates/', :compile-all },
    'All templates have valid syntax';

done-testing;
```
