# Cro Template Parts

## Motivation

Web applications often have common elements that appear on every page
(for example, showing the name of the currently logged in user, or showing
a summary of shopping basket contents).

While the template code to render these can be extracted using template
subs and macros, one would still need to have every call to  the `template`
sub provide the data they need to be rendered.

Template parts resolve this problem by providing an alternative way to
provide the data needed for these common elements.

## Basic usage

In the `route` block, one can write a template part data provider,
optionally taking the current user/session object. A template part can
return a single object or a `Capture`:

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

When this part is reached while rendering the template, the block that
was registered with `template-part` under the name `basket` will be
called in order to obtain the data.

## The special MAIN part

The part name `MAIN` can be used to provide access to the main data
that the template was given to render. For example, instead of using the
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
