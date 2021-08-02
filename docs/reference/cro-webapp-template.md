# Cro::WebApp::Template

Templates are typically used to render some data into HTML. The template engine
is designed with HTML in mind, and takes care to escape data as it should be
escaped in HTML. Templates are compiled, typically on first use, for efficient
production of data. The template language includes conditionals, iteration,
subroutines, modules, and a number of other features.

Templates are typically stored either as files and reference by path, or as
resources (the latter being useful if the web application should be possible
to install as a Raku distribution, for example using `zef`).

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
route -> 'product', Int $id {
    my $product = $repository.lookup-product($id);
    template 'templates/product.crotmp', $product;
}
```

This is short for:

```
route -> 'product', Int $id {
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
route -> 'product', Int $id {
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

## Template compilation and auto-reload

Templates are compiled on first use and cached for the rest of the process
lifetime. To have them recompiled automatically on changes, set `CRO_DEV=1`
in the environment.

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

## Template language

The template language is designed to feel natural to Raku developers, taking
syntactic and semantic inspiration from Raku.

### Generalities

A template starts out in content mode, meaning that a template file consisting
of plain HTML:

```
<h1>Oh, hello there</h1>
<p>I've been expecting you...</p>
```

Will result in that HTML being produced.

Syntax significant to the templating engine consists of a HTML-like tag that
begins with a non-alphabetic character. Some stand alone, such as `<.foo>` and
`<$foo>`, while others have a closer, like `<@foo>...</@>` The closers do not
require one to write out the full opener again, just to match the "sigil". One
may repeat the opening alphabetic characters of an opener in the closer if
desired, however (so `<@foo>` could be closed with `</@foo>`).

### The topic variable

As with Raku, there is a notion of current topic, like the Raku `$_`. The data
that is passed to the template to render is placed into the topic, and for
simple templates one can access properties from that. More complex templates
can instead use the parts mechanism, described later.

### Unpacking hash and object properties

The `<.name>` form can be used to access object properties of the current topic.
If the current topic does the `Associative` role, then this form will prefer to
take the value under the `name` hash key, falling back to looking for a method
`name` if there is no such key. Failure to find the method is a soft failure in
the case of an `Associative` (e.g. it just produces `Nil`), and an exception
otherwise.

For example, given a template `greet.crotmp`:

```
<p>Hello, <.name>. The weather today is <.weather>.</p>
```

Rendered with a hash:

```
template 'greet.crotmp', {
    name => 'Dave',
    weather => 'rain'
}
```

The result will be:

```
<p>Hello, Dave. The weather today is rain.</p>
```

The hash fallback is to ease the transition from using a `Hash` at first, and
then refactoring towards a model object later on.

Various other forms are available:

* `<.elems()>` will always be a method call, even if used on an `Associative`
  (so can be used to overcome the key fallback)
* `<.<elems>>` will always be a hash index
* `<.[0]>` indexes the array element 0, assuming the topic is indexable
* `<.{$key}>` can be used to do indirect hash indexing
* `<.[$idx]>` can be used to do indirect array indexing

These can all be chained, thus allowing for things like `<.foo.bar.baz>` for
digging into objects/hashes. When using the indexer forms, then only the
leading `.` is required, thus `<.<foo>.<bar>>` could be written instead as
`<.<foo><bar>>`.

The result of the indexing or method call will be strigified, and then HTML
encoded for insertion into the document.

### Variables

Various Cro template constructs introduce variables. These include iteration,
subroutines, macros, and parts. Note that variables that are in scope in the
`route` block at the location `template` is called are *not* in scope in the
template; only variables explicitly introduced inside of the template can be
referenced.

The `<$...>` syntax is used to refer to a variable. It will be stringified,
HTML encoded, and inserted into the document. It is a template compilation time
error to refer to a variable that does not exist. The current topic can be
accessed as `<$_>`, and this is the only variable that is in scope at the start
of a template.

It is allowed to follow the variable with any of the syntax allowed in a
`<.foo>` tag, for example `<$product.name>` or `<$product<name>>`. For
example, assuming we were inside a construct that defined the variables
`$person` and `$weather`, then:

```
<p>Hello, <$person.name>. The weather is <$weather.description>, with a low of
  <$weather.low>C and a high of <$weather.high>C.</p>
```

Would render something like:

```
<p>Hello, Darya. The weather is sunny, with a low of
  14C and a high of 25C.</p>
```

### Iteration

The `@` tag sigil is used for iteration. It may be used with any `Iterable`
source of data, and must have a closing tag `</@>`. The region between the
two will be evaluated for each value in the iteration, and by default the
current target will be set to the current value.

For example, given the template:

```
<select name="country">
  <@countries>
    <option value="<.alpha2>"><.name></option>
  </@>
</select>
```

And the data:

```
{
    countries => [
        { name => 'Argentina', alpha2 => 'AR' },
        { name => 'Bhutan', alpha2 => 'BT' },
        { name => 'Czech Republic', alpha2 => 'CZ' },
    ]
}
```

The result would be:

```
<select name="country">
    <option value="AR">Argentina</option>
    <option value="BT">Bhutan</option>
    <option value="CZ">Czech Republic</option>
</select>
```

The `<@foo>` form is short for `<@.foo>`, and follows the same rules as `<.foo>`
for resolution. It is also possible to write `<@$foo>` to iterate over a variable.

To specify a variable to declare and populate with the current iteration value
instead, place a `:` afterward the iteration target and name the variable. For
example, the earlier template could be written as:

```
<select name="country">
  <@countries: $c>
    <option value="<$c.alpha2>"><$c.name></option>
  </@>
</select>
```

Which leaves the current default target in place. Should the current target
itself be `Iterable`, it is permissible to write simply `<@_>...</@>`.

If the opening and closing iteration tags are the only thing on the line, then
no output will be generated for those lines, making the output more pleasant.

### Conditionals

The `?` and `!` tag sigils are used for conditionals. They may be followed by
either a `.` and then a topic access (for example, `<?.is-admin>...</?>`) or
by a variable (`<!$user.is-admin>...</!>`).

For more complex conditions, a subset of Raku expressions is accepted, using
the syntax `<?{ $a eq $b }>...</?>`. The only thing notably different from
Raku is that `<?{ .answer == 42 }>...</?>` will have the same hash/object
semantics as in `<.answer>`, for consistency with the rest of the templating
language.

The following constructs are allowed:

* Variables (`$foo`)
* Use of the topic, method calls, and indexing, to the degree supported by the
  `<.foo>` tag syntax
* Parentheses for grouping
* The comparison operations `==`, `!=`, `<`, `<=`, `>=`, `>`, `eq`, `ne`, `lt`,
  `gt`, `===`, and `!===`
* The `&&`, `||`, `and` and `or` short-circuit logic operators
* The `+`, `-`, `*`, `/`, and `%` math operations
* The `~` and `x` string operations
* Numeric literals (integer, floating point, and rational)
* String literals (single quoted, without interpolation)

Those wishing for more are encouraged to consider writing their logic outside of
the template.

If the opening and closing condition tags are the only thing on the line, then
no output will be generated for those lines, making the output more pleasant.

### Subroutines

It is possible to declare template subroutines that may be re-used, in order to
factor out common elements.

A simple template subroutine declaration looks like this:

```
<:sub header>
  <header>
    <nav>
      blah blabh
    </nav>
  </header>
</:>
```

It can then be called as follows:

```
<&header>
```

It is possible to declare a template sub that takes parameters:

```
<:sub select($options, $name)>
  <select name="<$name>">
    <@$options>
      <option value="<.value>"><.text></option>
    </@>
  </select>
</:>
```

And then call it with arguments:

```
<&select(.countries, 'country')>
```

The arguments may be an expression as valid in a <?{ ... }> condition - that is,
literals, variable access, dereferences, and some basic operators are allowed.

As in Raku, you can have named - optional - arguments as well:

```
<:sub haz(:$name)>
  I can haz <$name>!
</:>

<&haz(:name('named arguments'))>
```

Defaults can also be set (and implicitly make positional parameters optional too):

```
<:sub result($value = 0, :$unit = 'kg')>
  <$value> <$unit>
</:>
```

### Macros

A template macro works somewhat like a template subroutine, except that the usage
of it has a body. This body is passed as a thunk, meaning that the macro can choose
to render it 0 or more times), optionally setting a new default target. For example,
a macro wrapping some content up in a Bootstrap card might look like:

```
<:macro bs-card($title)>
  <div class="card" style="width: 18rem;">
    <div class="card-body">
      <h5 class="card-title"><$title></h5>
      <:body>
    </div>
  </div>
</:>
```

Where `<:body>` marks the point for the body to be rendered. This macro could
be used as:

```
<|bs-card('My Stuff')>
  It's my stuff, in a BS card!
</|>
```

To set the current target for the body in a macro, use `<:body $target>`.

### Inserting HTML and JavaScript

Everything is HTML escaped by default. However, sometimes it is required to
place a blob of pre-rendered HTML into the template output. There are two
ways to achieve this.

* The `HTML` built-in function, called as `<&HTML(.stuff)>`, first checks
  that there is no `script` tag or attribute starting with `javascript:`;
  if there are any, it will consider this as an XSS attack attempt and
  throw an exception.
* The `HTML-AND-JAVASCRIPT` built-in function does not attempt any XSS
  protection, and simply inserts whatever it is given without any kind of
  escaping.

Note that the `HTML` function does not promise completely foolproof
XSS protection. **Use both of these functions very carefully.**

## Template modules

### Within the application

Template subs and macros can be factored out into other template files, and
then imported with `<:use ...>`, passing the filename as a string literal:

```
<:use 'common.crotmp'>
```

### In the module ecosystem

It is also possible to create libraries of Cro template subs and macros, for
reuse across multiple applications and potentially for publication in the Raku
ecosystem. Such a library should:

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

## Template parts

Often web applications will have common elements that appear on every page
(for example, showing the name of the currently logged in user, or showing
a summary of shopping basket contents). While the template to render these
 can be extracted using template subs and macros placed in a separate file
and imported with use`, one would still need to have every call to the
`template` sub provide the data they need to be rendered.

Template parts resolve this problem. In the `route` block, one can write a
template part data provider, optionally taking the current user/session
object. A template part can return a single object or a `Capture`:

```
template-part 'basket', -> MySession $user {
    given $user.basket {
        \( :items(.items), :value(.total-value) )
    }
}
```

Meanwhile, in the template, one can write a `part` implementation that
receives the data:

```
<:part basket(:$items, :$value)>
  <?$items>
    <$items> items worth <$value> EUR
  </?>
</:>
```

Additionally, the part name `MAIN` can be used to provide access to the main
data the template was given to render. For example, instead of using the
topic:

```
<p>Hello, <.name>. The weather today is <.weather>.</p>
```

One could instead do:

```
<:part MAIN($data)>
  <p>Hello, <$data.name>. The weather today is <$data.weather>.</p>
</:part>
```

Further, one can pass a capture to the `template` function:

```
template 'overview.crotmp', \($db.get-sales(), $db.get-traffic());
```

And bind the values into variables in the template:

```
<:part MAIN($sales, $traffic)>
  ...
</:>
```

Which will be easier to handle in more complex templates than having all data
accessed using the topic.
