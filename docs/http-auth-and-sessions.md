# HTTP Authentication, Authorization, and Sessions

This document provides an overview of how authentication, authorization, and
sessions can be handled in Cro for an HTTP application. Since applications
have a wide range of needs in this area, Cro makes it easy for applications to
plug in their own session and auth handling. At the same time, it provides a
range of components to handle the most common cases.

## The auth property of Cro::HTTP::Request

The `auth` property of a `Cro::HTTP::Request` is used to hold an object that
may represent any, or all, of:

* A current user
* A set of rights, or a means to check those rights
* Session data

For example:

* With basic authentication, there may not be any ongoing session, and the
  user is authenticated for each request. In this case, the object in `auth`
  would typically carry the username, potentially having methods on it to do
  lookups of further data about that user or fetch rights.
* With a JSON Web Token, there is no ongoing session, and the object in `auth`
  would be populated from the data in the web token, provided that the token
  can be verified.
* With a web-based login (login form on a page), typically there will be a
  session object with fields indicating if there is currently a logged in
  user. The login process would update the sesion object with that information
  at the time of login, and clear it at the time of logout.
* For a system without any kind of login, but that simply wishes to hold some
  information about a particular session, then the object would just represent
  that session information.

Cro does not place any constraints on the type of the object in `auth`; the
contents of this session and/or user object is left for the application to
define as it needs. However, it will be most convenient for use with the HTTP
router if the object does the `Cro::HTTP::Auth` role (which is a simple marker
role).

The `auth` property will typically be set by a piece of request middleware.
Cro provides a number of options, some built-in and others as modules that
can be installed independently.

## Router Support

The signature of a route may start with a positional parameter that:

* Is constrained by a type that does the `Cro::HTTP::Auth` role
* Is marked with the `is auth` trait (this is less convenient, but allows for
  the case where an existing object should be used, but it is not desirable to
  couple it to Cro)

Such a parameter will not be treated as the first route segment, but instead
will be populated with the contents of the `auth` property of the
`Cro::HTTP::Request` being processed. The type constraint will also be
checked; should it fail, then a HTTP 401 Unauthorized responses will
automatically be produced (which middleware may later rewrite into a redirect
to a login page, if applicable).

For systems where there are different kinds of user, it can be convenient to
create `subset` types to describe them:

```
subset Admin of My::App::Session where .is-admin;
subset LoggedIn of My::App::Session where .is-logged-in;
```

And then use them in routes like this:

```
my $app = route {
    get -> LoggedIn $user, 'my', 'profile' {
        # Use $user in some way
    }

    get -> Admin, 'system', 'log' {
        # Just use the type and don't name a variable, if the session/user
        # object is not needed
    }
}
```

Note that middleware that populates `auth` must be installed either at the
server level *or* in a `route` block that **delegates** to this one (*not*
`include`s it).

## In-memory session management

The `Cro::HTTP::Session::InMemory[::T]` role implements simple in-memory
session management, using a cookie to store the session ID. This is useful in
web applications. The type used to represent the session data is to be
provided by the application. For example:

```
class My::App::Session {
    has $.is-logged-in;
    has $.admin;
    has @.recently-viewed-items;
}
```

Could be used as session state by applying this middleware, either in a `route`
block:

```
my $app = route {
    before Cro::HTTP::Session::InMemory[My::App::Session].new(
        expiration => Duration.new(60 * 15),
        cookie-name => 'MY_SESSION_COOKIE_NAME'
    );

    delegate <*> => route {
        # Protected routes here...
    }
}
```

Or at server level (pass it to the `before` parameter of `Cro::HTTP::Server`).

The default expiration time is 30 minutes, and this impacts both the `max-age`
set on the cookie as well as the time before session state is deleted from
memory. If no cookie name is provided, a random name will be generated (to
help avoid being able to fingerprint the application platform by its session
cookie name).

Since the session state is stored in memory, it will be lost when the service
is restarted. Architecturally, it also prevents scaling out beyond a single
process. In short, this is convenient for development purposes, and may be
enough for some simple, low-traffic, applications. Consider switching to, or
even starting with, `Cro::HTTP::Session::Persistent` instead in order to
provide better scalability and user experience.

**Important:** The security of this session mechanism depends on the secrecy
of the session cookie, which will be sent with every request (this applies not
just to Cro, but to HTTP sessions in general). Therefore, HTTPS should be used
in production deployments that use this mechanism.

## Persistent session management

The `Cro::HTTP::Session::Persistent[::T]` role implements session state, with
the state being persisted (for example, in a database or key/value store). To
use it, one must implement the methods for saving a session state, loading a
session state (updating the last seen timestamp), and clearing outdated
session state.

```
class MySession does Cro::HTTP::Auth {
    has $.is-logged-in;
    has $.admin;
    has @.recently-viewed-items;
}
class MySessionStore does Cro::HTTP::Session::Persistent[MySession] {
    # This will be called whenever we need to load session state, and the
    # session ID will be passed. Return `fail` if it is not possible
    # (e.g. no such session is found).
    method load(Str $session-id --> MySession) {
        !!! 'Load session $session-id, place data into a new MySession instance'
    }

    # This method is optional, and will be called when a new session starts.
    # It by default does nothing, but may be convenient for databases with a
    # INSERT/UPDATE distinction (in which case this would be the initial
    # INSERT, and the save method would be an UPDATE). In other databases,
    # this distinction may not exist. This method may return an instance of
    # the session object; if it does not, one will be created automatically
    # (by calling `.new`).
    method create(Str $session-id) {
    }

    # This will be called whenever we need to save session state.
    method save(Str $session-id, MySession $session --> Nil) {
        !!! 'Save session $session under $session-id, probably with a timestamp'
    }

    method clear(--> Nil) {
        !!! 'Clear sessions older than the maximum age to retain them'
    }
}
```

There are no concrete implementations of this role in the Cro core. However,
`Cro::HTTP::Session::Redis` exists in the module ecosystem; other options will
likely be added with time.

**Important:** The security of this session mechanism depends on the secrecy
of the session cookie, which will be sent with every request (this applies not
just to Cro, but to HTTP sessions in general). Therefore, HTTPS should be used
in production deployments that use this mechanism.

## Basic Authentication

The `Cro::HTTP::Auth::Basic[::TSession, Str $username-prop]` role is a basis
for implementing basic authentication. The `TSession` parameter is the type of
the session object to go in `auth`, and `$username-prop` is the name of the
property to set to the username if authentication succeeds (`Nil` will be
assigned otherwise). 

In the case the request's `auth` property is empty, then an instance of the
`TSession` object will be created, passing `username-prop` as a parameter
(so if `$username-prop` was set to `username`, then it would call
`MySession.new(username => $the-username)`). If `auth` already contains an
object, it would do `$that-object.username = $the-username` (and thus the
property must be `rw`). This makes it possible to apply a session middleware
before this middleware, and have the current user added to the data.

The role requires the `authenticate` method to be implemented. It is passed
the username and password to authenticate, and should return `True` if it is
a valid combination and `False` otherwise.

```
class MyUser {
    has $.username;
}
class MyBasicAuth does Cro::HTTP::Auth::Basic[MyUser, "username"] {
    method authenticate(Str $user, Str $pass --> Bool) {
        # No, don't actually do this!
        return $user eq 'c-monster' && $pass eq 'cookiecookiecookie';
    }
}
```

## JSON Web Tokens

The `Cro::HTTP::Auth::WebToken` is a base role for verifying JSON Web
Tokens.  It has `secret` and `public-key` attributes for password or
OpenSSL's public key accordingly. Either password or public key must
be set. When a request is and decode it using either password or
public key. When both `secret` and `public-key` attributes are set,
`public-key` will be used to decode token.

In case when key pair is used, `RS256` algorithm is used, otherwise
`HS256` is used.

`auth` attribute will be populated with `Nil` if method
`get-token($request)` returned `Nil` or died with an
exception. In case of success, it must return `Str`.

This role has method `set-auth($request, $result)`, that is called to
set `auth` attribute of a given request. As result of JSON decoding
may not do `Cro::HTTP::Auth` and so made request unable to be sent to
a correct route, `Cro::HTTP::Auth::WebToken::Token` wrapper class that
does `Cro::HTTP::Auth` role is used. It has a single `token` property
that is populated with the result of decoding JSON Web Token by
default on calling a `set-auth` method.

The `Cro::HTTP::Auth::WebToken::Bearer` is a role that does
`Cro::HTTP::Auth::WebToken`. Its `get-token` method is overridden to
take the token from `Auth` header of the request object. `set-auth` method
may be overridden by the user to set a custom object that does
`Cro::HTTP::Auth` role to `auth` attribute. It is installed as
middlewere, either at route block or server level.

The `Cro::HTTP::Auth::WebToken::FromCookie[Str $cookie-name]` is a
role that does `Cro::HTTP::Auth::WebToken`. Its `get-token` method is
overridden to take the token from the request's cookie with given name
`$cookie-name`. `set-auth` method may be overridden by the user to set
a custom object that does `Cro::HTTP::Auth` role to `auth`
attribute. It is installed as middlewere, either at route block or
server level. Additionally, this role checks `exp` claim of parsed
token. In case it is invalid, the cookie will be removed from the
request.

## Web form based login

This can be implemented by picking a session storage mechanism, and having a
field in the user/session object that indicates the user is logged in, with
some information about rights perhaps included. Since the details of login
forms and user databases vary greatly, Cro does not provide a built-in way to
achieve this. It is possible some drop-in solutions for more quickly getting
started with new applications will be published as a module in the future,
however.

The basic recipe is as follows:

```
class UserSession does Cro::HTTP::Auth {
    has $.username is rw;

    method logged-in() {
        defined $!username;
    }
}

my $routes = route {
    subset LoggedIn of UserSession where *.logged-in;

    get -> UserSession $s {
        content 'text/html', "Current user: {$s.logged-in ?? $s.username !! '-'}";
    }

    get -> LoggedIn $user, 'users-only' {
        content 'text/html', "Secret page just for *YOU*, $user.username()";
    }

    get -> 'login' {
        content 'text/html', q:to/HTML/;
            <form method="POST" action="/login">
              <div>
                Username: <input type="text" name="username" />
              </div>
              <div>
                Password: <input type="password" name="password" />
              </div>
              <input type="submit" value="Log In" />
            </form>
            HTML
    }

    post -> UserSession $user, 'login' {
        request-body -> (:$username, :$password, *%) {
            if valid-user-pass($username, $password) {
                $user.username = $username;
                redirect '/', :see-other;
            }
            else {
                content 'text/html', "Bad username/password";
            }
        }
    }

    sub valid-user-pass($username, $password) {
        # Call a database or similar here
        return $username eq 'c-monster' && $password eq 'cookiecookiecookie';
    }
}

my $app = route {
    # Apply middleware, then delegate to the routes.
    before Cro::HTTP::Session::InMemory[UserSession].new;
    delegate <*> => $routes;
}
```
