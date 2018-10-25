# Structuring services built with Cro

Setting up a simple Cro service serving a handful of routes is pretty easy:
stick them into a `route` block, pass it to the HTTP server, and that's it.
The `cro stub` HTTP templates place that `route` block in a module, leaving
the server setup to be done in a `service.p6` script. This means that unit
tests can `use` the module with the `route` block, and tests can be written
using `Cro::HTTP::Test`.

This will suffice for small, simple services. However, it won't make for a
maintainable system once one reaches tens or hundreds of routes. This
document explores some ways to structure larger applications and services,
and keep them testable.

## Cro is not a framework

Cro is a set of tools and libraries, rather than a framework. This may sound
like an academic point, and Cro's designers fully expect it will be variously
called a "web framework", "service framework", and so forth. However, the
distinction does come with some consequences.

The line between library and framework is blurry, but in general, frameworks
own the "main loop" of a program and call your code, while libraries are code
that you call. Further, frameworks tend to assume that applications revolve
around them, and so have no qualms about providing an overall structure. By
contrast, libraries expect to be just one ingredient in the program pie. Thus,
Cro does not try to impose an overall architecture on programs using it.

Frameworks do, however, provide some comfort that one is heading in a
reasonable direction. This document provides design/architecture suggestions
for those building Cro HTTP services and applications, and wondering how one
might structure them as they become larger.

## Keep route handlers focused

Much of software design is about working out what belongs where. Cro route
handlers are the place to implement the mapping between HTTP and your model
(where the model may be a domain model, a data model, etc.) Thus, it's quite
reasonable for `route` handlers to:

* Enforce authentication/authorization (typically through a `subset` type on
  the request auth object)
* Map the request to an appropriate bit of model logic
* Transform the data in the request into a command object or model object
* Map the results of an operation into a HTTP response
* Map any model errors into the appropriate HTTP error

However, avoid:

* Doing database queries directly from the `route` handler
* Putting business logic in the route handler

Instead, factor these out into separate functions or objects, as appropriate.
This means it is possible to test the route handlers and, potentially, the
business logic in isolation. It also will make it easier to refactor, and to
re-use the same logic in a non-Cro context in the future if required.

## Don't have one giant `route` block

The `Cro::HTTP::Router` provides both `include` and `delegate` for composing
applications out of many `route` blocks. So, instead of:

```
sub routes() is export {
    route {
        get -> 'images', *@path {
            static 'resources/images', @path;
        }

        get -> 'css', $file {
            static 'frontend-build/css', $file;
        }

        get -> 'product', $id {
            ... "route handler goes here"
        }
    }
}
```

One can pull the route handlers for serving assets out:

```
sub routes() is export {
    route {
        include assets();

        get -> 'product', $id {
            ... "route handler goes here"
        }
    }
}

sub assets() {
    route {
        get -> 'images', *@path {
            static 'resources/images', @path;
        }

        get -> 'css', $file {
            static 'frontend-build/css', $file;
        }
    }
}
```

These can be spread over multiple modules. Both `include` and `delegate`
support adding a prefix of one or more route segments to the URI also,
meaning there's no need to repeat it in every single route.

```
use Routes::Assets;
use Routes::Catalogue;
use Routes::Checkout;

sub routes() is export {
    route {
        # No prefix
        include asset-routes();
        # /catalogue prefix
        include 'catalogue' => catalogue-routes();
        # /shop/checkout prefix
        include <shop checkout> => checkout-routes();
    }
}
```

Nested uses of `include` and `delegate` are permitted, to allow recursive
application of this approach.

With `include`, the routes from the nested router are included into the same
URI matcher, so in that sense it's much like they are textually included in
the `route` block that performs the `include`. However, any `before-matched`
and `after-matched` middleware inside of an included `route` block will only
apply to the routes inside of that block. For more details on middleware
handling, and on when to use `delegate` instead of `include`, see the section
on composing routes in the `Cro::HTTP::Router` documentation.

## A functional structure for dependencies

An application will not just have route handlers. Instead, the route handlers
will dispatch operations to, or request results from, other components (for
example, data access layers, data models, or domain objects). To enable
testing of `route` blocks in isolation from these, it is advisable to take
them as arguments to the `sub` enclosing the `route` block.

```
sub user-routes(MyApp::UserDB $db, MyApp::EmailSender $email) {
    route {
        get -> LoggedInUser $user, 'profile' {
            content 'application/json', $db.get-user-profile($user.id);
            CATCH {
                when X::MyApp::NoSuchUser {
                    not-found;
                }
            }
        }

        ...
    }
}
```

This facilitates testing of the logic in the route handlers in isolation from
these dependencies, for example by stubbing them using a module such as
`Test::Mock`.

These dependencies can in turn be passed along as needed to other `sub`s that
contain `route` blocks to be included.

Finally, the top-level entry point of the application initializes the real
versions of the various dependencies, and passes them in.

## An object-oriented structure

One might prefer a more object-oriented approach. This may come in useful if
wishing to use an existing dependency injection container, instead of passing
the dependencies down explicitly from the top level (which is fine up to a
point, but risks getting out of hand in a large application).

Imagine we have a DI container where an `is injected` trait specifies a
dependency provided by the container. We could instead place our `route`
block into a method inside of this, and use the dependencies.

```
unit class Routes::User;

has MyApp::UserDB $.db is injected;
has MyApp::EmailSender $.email is injected;

method routes() {
    route {
        get -> LoggedInUser $user, 'profile' {
            content 'application/json', $!db.get-user-profile($user.id);
            CATCH {
                when X::MyApp::NoSuchUser {
                    not-found;
                }
            }
        }
        ...
    }
}
```

A top-level `Routes` class might then depend on the various other route handler
classes.

```
unit class Routes;

has Routes::User $.user-routes is injected;

method routes() {
    route {
        include 'user' => $!user-routes.routes();
    }
}
```

One then writes tests by constructing the objects with test doubles (mocks,
stubs, etc.) instead of the real thing that the container would use. The
top-level `route` block is obtained by having the container construct the
dependency tree, and calling the `routes` method on the resulting object.

## A note on concurrency

Route handlers may run in parallel, on multiple threads. This means that any
state held inside of the `sub` or `class` holding the route block must be
OK with that.

If the model logic consists of making calls to a database, then there's not
much to worry about so long as the underlying database drivers are good with
that (for example, `DB::Pg` will handle this situation well). However, if the
application has in-memory state, it will need to be protected.
