# Cro Template Syntax

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

## The topic variable

As in Raku, there is a notion of current topic - the `$_` variable - and
some conveniences for working with it. The data that is passed to the
template to render is placed into the topic, and for simple templates one
can access properties from that. More complex templates can instead use
the parts mechanism, described later.

## Indexing hash, array, and object data

The `<.name>` form can be used to access object properties of the current topic.
If the current topic does the `Associative` role, then this form will prefer to
take the value under the `name` hash key, falling back to looking for a method
`name` if there is no such key. Failure to find the method is a soft failure in
the case of an `Associative` (it produces `Nil`), and an exception otherwise.

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

* `<.elems()>` with parentheses will always be a method call, even if used
  on an `Associative` (so can be used to overcome the key fallback)
* `<.<elems>>` will always be a hash index
* `<.[0]>` indexes the array element 0
* `<.{$key}>` can be used to do indirect hash indexing
* `<.[$idx]>` can be used to do indirect array indexing

These can all be chained, thus allowing for things like `<.foo.bar.baz>` for
digging into objects/hashes. When using the indexer forms, then only the
leading `.` is required, thus `<.<foo>.<bar>>` could be written instead as
`<.<foo><bar>>`.

The result of the indexing or method call will be strigified, and then HTML
encoded for insertion into the document.

## Variables

Various Cro template constructs introduce variables. These include iteration,
subroutines, macros, and parts. Note that variables that are in scope in the
`route` block at the location `template` is called are *not* in scope in the
template; only variables explicitly introduced inside of the template can be
referenced.

The `<$name>` syntax is used to refer to a variable. It will be stringified,
HTML encoded, and inserted into the document. It is a template compilation time
error to refer to a variable that does not exist. The current topic can be
accessed as `<$_>`, and this is the only variable that is in scope at the start
of a template.

It is allowed to follow the variable with any of the syntax allowed in a
`<.foo>` tag, for example `<$product.name>` or `<$product<name>>`. For
example, assuming we were inside a construct that defined the variables
`$person` and `$weather`, for example:

```
<:sub greeting($person, $weather)>
  <p>Hello, <$person.name>. The weather is <$weather.description>, with a low of
    <$weather.low>C and a high of <$weather.high>C.</p>
</:>
```

Then calling the template sub would render something like:

```
<p>Hello, Daria. The weather is sunny, with a low of
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

It is possible to avoid repetition and risk by using the "structured tag" syntax.
This allows the previous example:

```
<select name="country">
  <@countries>
    <option value="<.alpha2>"><.name></option>
  </@>
</select>
```

To be abbreviated as:

```
<select name="country">
  <@countries option value="<.alpha2>"><.name></@>
</select>
```

That is, the `option` opening tag will be emitted, and a matching closing
`</option>` will be produced as if written prior to the `</@>`

The `<@foo>` syntax is short for `<@.foo>`, and follows the same rules as `<.foo>`
for resolution. It is also possible to write `<@$foo>` to iterate over a variable,
and to index properties, for example `<@$band.rockstars>`.

To specify a variable to declare and populate with the current iteration value
instead, place a `:` afterward the iteration target and name the variable. For
example, the earlier template could be written as:

```
<select name="country">
  <@countries : $c>
    <option value="<$c.alpha2>"><$c.name></option>
  </@>
</select>
```

Which leaves the current topic in place. This can also be used with the
structured tag syntax:

```
<select name="country">
  <@countries : $c option value="<$c.alpha2>"><$c.name></@>
</select>
```

If the opening and closing iteration tags are the only thing on the line, then
no output will be generated for those lines, making the output more pleasant.

Sometimes one wants to emit a separator between values (but that should not
be repeated after the final value). Such a separator can be specified using the
`<:separator>...</:>` tag directly within the body of the iteration:

```
<@news>
  <h3><.headline></h3>
  <p><.body></p>
  <:separator>
    <hr/>
  </:>
</@>
```

## Conditionals

The `?` and `!` tag sigils are used for conditionals. They may be followed by
either a `.` and then a topic access (for example, `<?.is-admin>...</?>`) or
by a variable (`<!$user.is-admin>...</!>`). For example:

```
<?.is-admin>
  <p>You are an admin! Much wow!</p>
</?>
<!$basket.products>
  <span class="panic">Your basket is empty. Quick, buy something!</span>
</!>
```

The structured tag form could be used instead, whereby the tag that should
be opened and later closed is specified after the condition. The prior
example could thus be written more compactly as:

```
<?.is-admin p>
  You are an admin! Much wow!
</?>
<!$basket.products span class="panic">
  Your basket is empty. Quick, buy something!
</!>
```

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

## Subroutines

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

A template sub may take parameters:

```
<:sub select($options, $name)>
  <select name="<$name>">
    <@$options>
      <option value="<.value>"><.text></option>
    </@>
  </select>
</:>
```

And called with arguments:

```
<&select(.countries, 'country')>
```

The arguments may be an expression as valid in a `<?{ ... }>` condition - that is,
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

## Macros

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

## Comments

While standard HTML comment syntax may be used inside of templates, they will
be passed straight along into the rendered output. An alternative syntax is
available for template comments, which are discarded at the point the template
is being parsed, and so never make it into the output.

```
<p>This is rendered!</p>
<!-- And this comment goes to the client too -->
<#>But this is not</#>
```

Template comments may span multiple lines and contain tags (both HTML ones and
template syntax):

```
<h2>Offers</h2>
<p>All of our offers are currently unavailable!</p>
<#>
<ul>
  <@offers li><$_></@>
</ul>
</#>
```
