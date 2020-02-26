# Cro::WebApp::Template

Templates are typically used to render some data into HTML. The template engine
is designed with HTML in mind, and takes care to escape data as it should be
escaped in HTML. A template is compiled once into Raku code, and then may be
used many times by passing it different input. The input data can be any Raku
object, including a `Hash` or `Array`.

## Using a template

To use templates, add a `use Cro::WebApp::Template;` at the top of the file
containing the routes where they are to be used.

To render a template as the result of a route, use `template`:

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
response along with the body. Note that by default `template` is setting a
content type of `text/html`; to have it not do so, pass `content-type`:

```
route -> 'product', Int $id {
    my $product = $repository.lookup-product($id);
    template 'templates/product.crotmp', $product,
        content-type => 'text/plain';
}
```

The `$product` will become the topic of the template to render (see below for
more on the template language).

## Template locations and compilation

By default, templates will be looked for in the current working directory, and
`<:use '...'>` directives in templates do the same. Templates will also be
compiled lazily on first use.

Call the `template-location` function in order to specify a directory where
templates can be located. These calls prepend to the search path, so the latest
call to `template-location` will take precedence. Doing:

```
template-location 'templates/';
```

Means that templates underneath the `templates/` directory will be found without
needing to be qualified with that path. Optionally passing `:compile-all` will
immediately compile all of the templates and die if there are any errors. This
could be put into a test case:

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

## Generalities

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

As with Raku, there is a notion of current topic, like the Raku `$_`.

## Unpacking hash and object properties

The `<.name>` form can be used to access object properties of the current topic.
If the current topic does the `Associative` role, then this form will prefer to
take the value under the `name` hash key, falling back to looking for a method
`name` if there is no such key. Failure to find the method is a soft failure in
the case of an `Associative` (e.g. it just produces `Nil`), and an exception
otherwise.

For example, given a template:

```
<p>Hello, <.name>. The weather today is <.weather>.</p>
```

Rendered with a hash:

```
{
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
leading `.` is required, thus `<.<foo>.<bar>>` could be just `<.<foo><bar>>`.

The result of the indexing or method call will be strigified, and then HTML
encoded for insertion into the document.

## Variables

The `<$...>` syntax can be used to refer to a variable. It will be stringified,
HTML encoded, and inserted into the document. It is a template compilation time
error to refer to a variable that does not exist. The current topic can be
accessed as `<$_>`.

It is allowed to follow the variable with any of the syntax allowed in a
`<.foo>` tag, for example `<$product.name>` or `<$product<name>>`. For
example assuming the variables `$person` and `$weather` are defined, then:

```
<p>Hello, <$person.name>. The weather is <$weather.description>, with a low of
  <$weather.low>C and a high of <$weather.high>C.</p>
```

Would render something like:

```
<p>Hello, Darya. The weather is sunny, with a low of
  14C and a high of 25C.</p>
```

## Iteration

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
itself be `Iterable`, it is permissible to write simply `<@_>...</@_>`.

If the opening and closing iteration tags are the only thing on the line, then
no output will be generated for those lines, making the output more pleasant.

## Conditionals

The `<?$foo>...</?>` ("if") and `<!$foo>...</!>` ("unless") may be used for
conditional execution. These perform a boolean test on the specified variable.
It is also allowed to use them with the topic deference syntax, such as
`<?.is-admin>...</?>`, or variables and dereferences together, such as
`<?$user.is-admin>...</?>`. For more complex conditions, a subset of Raku
expressions is accepted, using the syntax `<?{ $a eq $b }>...</?>`. The only
thing notably different from Raku is that `<?{ .answer == 42 }>...</?>` will
have the same hash/object semantics as in `<.answer>`, for consistency with the
rest of the templating language.

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

## Subroutines and macros

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
    <@options>
      <option value="<$value>"><$text></option>
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
<|bs-card("My Stuff")>
  It's my stuff, in a BS card!
</|>
```

To set the current target for the body in a macro, use `<:body $target>`.

## Factoring out subs and macros within an application

Template subs and macros can be factored out into other template files, and
then imported with `<:use ...>`, passing the filename as a string literal:

```
<:use 'common.crotmp'>
```

## Providing modules that export template subs and macros

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

## Inserting HTML and JavaScript

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
