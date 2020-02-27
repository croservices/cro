# Cro::WebApp::Form

Collecting data from forms is a common requirement in web applications. The
`Cro::WebApp::Form` module aims to take much of the tedium out of doing so.
It works as follows:

* One defines a form by writing a `class`, using traits to specify the form
  controls and validation requirements. The class should do the
  `Cro::WebApp::Form` role.
* The `Cro::WebApp::Template` standard library includes a `&form` built-in
  that can be used to render the form without having to write out the form
  HTML.
* An empty instance of the form can be created using the `empty` method on
  the form class. 
* A `form-data` router function can be used to obtain an instance of the
  class constructed with submitted form data. The `is-valid` method can be
  called to check if it is valid; if it is not, it can be re-rendered using
  the template, and validation errors will be displayed.

## A basic example

### Defining the form

Consider the following example:

```
class Review does Cro::WebApp::Form {
    has Str $.name is required;
    has Int $.rating is required will select { 1..5 };
    has Str $.comment is multiline(:5rows, :60cols) is maxlength(1000);
}
```

This defines a form with three fields:

* A name, which will be rendered as a textbox
* A rating, which will be a select dropdown box with the options 1 through 5
* A comment, which will be rendered as a text area of 5 rows and 60 columns

Validation wise, the first two fields are required, while the third has a maximum
length of 1000 characters.

### A template to render it

The `&form` builtin can be used to render a form. For example, we can set up a
`review.crotmp` template to render the form like this:

```
<html>
  <body>
    <h1>Submit a review</h1>
    <&form(.form, :submit-button-text('Send your review'))>
  </body>
</html>
```

### The routes

Given the form and template, the routes can be defined as follows:

```
sub routes() is export {
    route {
        # Render an empty form first
        get -> {
            template 'templates/review.crotmp', { form => Review.empty }
        }

        # When it is submitted, validate it, and render it again with validation
        # errors if there are problems. Otherwise, accept the review.
        post -> {
            form-data -> Review $form {
                if $form.is-valid {
                    note "Got form data: $form.raku()";
                    content 'text/plain', 'Thanks for your review!';
                }
                else {
                    template 'templates/review.crotmp', { :$form }
                }
            }
        }
    }
}
```

## Defining forms

Each attribute in the form `class` with an accessor (that is, declared like
`has $.foo`) will result in a form field. You may add further private attributes
and methods to the form class as you wish; for example, it may be convenient to
have the form class carry methods to load and save itself using a database.

### Attribute types

The `$` sigil should be used for most attributes, with the exception of the
case of a multi-select list, where `@` may be used instead.

An attribute with no type is equivalent to one typed with `Str`. It is also allowed
to use the numeric types `Int`, `Rat`, and `Num`. The values will be parsed into
these types, and a validation error produced if they are malformed. This will also
cause the generation of a `number` input type in the rendered HTML.

Finally, use of `Bool` will result in a checkbox.
 
### Form controls

Traits are used to describe the kinds of controls that will be used on a form. The
full set of HTML5 control types are available. Remember to check browser support for
them is sufficient if needing to cater to older browsers. They mostly follow the HTML 5
control names, however in a few cases alternative names are offered for convenience.
Taking care to use `is email` and `is telephone` is especially helpful for mobile users.

* `is password` - a password input
* `is number` - a number input (set implicitly if a numeric type is used)
* `is color` - a color input
* `is date` - a date input
* `is datetime-local` / `is datetime` - a datetime-local input
* `is eamil` - an email input
* `is month` - a month input
* `is multiline` - a multiline text input (rendered as a text area); can have the number
  of rows and columns specified as named arguments, such as `is multiline(:5rows, :60cols)`
* `is tel` / `is telephone` - a tel input for a phone number
* `is search` - a search input
* `is time` - a time input
* `is url` - a url input
* `is week` - a week input
* `will select { ... }` - a select input, offering the options specified in the block,
  for example `will select { 1..5 }`. If the sigil of the attribute is `@`, then it will
  render a multi-select box. While `self` is not available in such a trait, it is passed
  as the topic of the block, so one can write a `method get-options() { ... }` and then
  do `will select { .get-options }`. Note that currently there is no assistance with
  handling situations where the options should depend on another form field.

There is no trait for checkboxes; use the `Bool` type instead.

### Labels, help texts, and placeholders 

By default, the label for the control is formed by:

* Taking the attribute name
* Replacing each `-` with a space
* Calling `tclc` to title case it

Use the `is label('Name')` trait in order to explicitly set a label.

For text inputs, one can also set a placeholder using the `is placeholder('Text')`
trait. This text is rendered in the textbox prior to the user filling it.

Finally, one may use the `is help('...')` trait in order to provide help text. This
is displayed beneath the form field.

## Validation

The various standard HTML5 validations are available and can be set up using traits on
the form attributes. Some have been given aliases so as to allow for more Raku-ish code.

* `is min-length(5)` / `is minlength(5)` - set the minimum length of a text input
* `is max-length(500)` / `is maxlength(500)` - set the maximum length of a text input
* `is min(1)` - set the minimum value of a numeric input
* `is max(100)` - set the maximum value of a numeric input
* `is required` - indicates that the form field is required

All of these are validated both server side and result in the appropriate client side
attributes being placed on the form fields during form rendering.

Further server-side validation at the field level can be specified by using the
`is validated($match-me, 'Message')` trait, which will use the given validation error
message if the input values fails to smartmatch against the condition. For example,
it could be used with a regex:

```
has $.username is validated(/^<[A..Za..z0..9]>+$/, 'Only alphanumerics are allowed');
```

Or code (whatever code or block):

```
has Int $.places is validated(* %% 2, 'Must be an even number of places');
has Str $.title is validated({ !.contains('TODO') }, 'Title must not be still TODO');
```

Form-level validation is implemented by writing a `validate-form` method, which calls
`add-validation-error` with each problem it finds:

```
my class BlogPost does Cro::WebApp::Form {
    has Str $.title is required is minlength(5) is maxlength(100)
            is placeholder('Enter a title') is help('5 to 100 chars');
    has Str $.content is required is multiline(:5rows, :80cols)
            is minlength(5) is maxlength(100000);
    has Str $.category will select { 'Coding', 'Photography', 'Trains' };

    method validate-form(--> Nil) {
        if $!title eq $!content {
            self.add-validation-error("Cannot just repeat title as post body");
        }
    }
}
```

The validity of the form can be tested by calling `is-valid` on the form. Until this is
called, the validation errors will not be populated.

## Creating form instances

The form can be:

* Created empty using `TheForm.empty` (use this instead of `.new`, since that will give
  an error if `is required` fields are missing)
* Parsed from a `application/x-www-form-urlencoded` form body (`TheForm.parse($body)`);
  any values that don't parse into numeric types will be retained in a shadow storage so
  they can be rendered back to the browser along with the validation error, and missing
  required values also do not prevent construction
* Created like a normal object (`TheForm.new(|%values)`); this will enforce `is required`
  and type constraints

Typically, however, one shall not use `TheForm.parse`, but rather the `form-data` router
function:

```
post -> {
    form-data -> Review $form {
        if $form.is-valid {
            # Process it
            ...
        }
        else {
            # Render it with the errors
            ...
        }
    }
}
```

This function will:

* Look at the expected type of form by introspecting the type of the parameter to the
  block
* Obtain the request body, doing the `await` for you
* Pass it to the `parse` method of the appropriate form (in this case, `Review.parse($body)`)
* Invoke the block with the result of that

It does not trigger validation; this should be done with an explicit `is-valid` call.

## Rendering

The `&form` built-in template function can be used to render the form. It requires the
form object to be passed as a single named argument:

```
<&form(.form)>
``` 

It also takes a wide range of named arguments. Some control form behavior:

* `action` sets the `action` attribute of the form (where it submits to); by default
  it is not set, so the form submits back to the current URL
* `novalidate` sets the `novalidate` attribute of the form, disabling the browser's
  built-in client side validation

Some control texts used in the form:

* `submit-button-text` - the text placed on the form submit button
* `form-errors-text` - text that comes before form-level errors are rendered

Others allow CSS classes to be placed on form elements to style them:

* `input-group-class` - goes on the `div` enclosing the form label and control for
  most inputs, but not check boxes
* `input-label-class` - goes on the `label` element for an input, except check boxes
* `input-control-class` - goes on the `input` or `select` element for an input,
  except check boxes
* `check-group-class` - goes on the `div` enclosing a check box and its label
* `check-label-class` - goes on the `label` element for a check box
* `check-control-class` - goes on the `input` element for a check box
* `was-validated-class` - applied to to form only if it was validated (so not applied
  when an empty form is rendered)
* `is-invalid-class` - applied to form controls that fail validation
* `invalid-feedback-class` - applied to the validation message for a control
* `form-errors-class` - applied to the `div` rendered above any form controls when there
  are form-level validation errors; this contains a `ul` which in turn has an `li` for
  each error
* `help-class` - applied to the element containing a control's help text
* `submit-button-class` - applied to the submit button

## CSRF protection

Provided the form is processed and rendered in the dynamic scope of a route handler, CSRF
protection will automatically be applied. This is achieved by use of the Double Submit
Cookie approach: a session cookie is set with a random token (if one is already present,
it will be re-used), and then this token is also placed into a hidden field in the form.
