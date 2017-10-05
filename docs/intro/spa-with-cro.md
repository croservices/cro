# Building a Single Page Application with Cro

This tutorial walks through building a simple Single Page Application using
Cro as the backend. For the frontend, we'll use webpack, ES6, React and Redux.
No prior knowledge of these is required, although expect to need to do some
further reading if you want to use them well in your own applications.

The [code is available](https://github.com/croservices/sample-app-spa-react).
At various points during the tutorial, the present state is committed. The
repository history matches the tutorial exactly, so you can use it to get an
overview of the changes at each step, or to see what you missed if you're
trying to follow along by building this from scratch.

## What you'll need

* To have installed Cro (see [this guide](getstarted) for help with that)
* To have installed `npm` (the Node.js package manager, which we'll use to
  get packages we need to build the frontend); on Debian-based Linux distros
  that's just `sudo apt install npm`

## What we'll be building

So we're at a food festival. Or a beer festival. Or any event with a bunch of
stuff that we could try. But...what to try? If only there was some app where
people could leave their tips about what's hot and what's not, and we could
see them in real time! If there'd been such a thing at the last beer festival
I went to, I might have been spared that green tea beer...

So, we'll make a SPA that supports:

* Submitting new tips (a POST to the backend)
* Having the latest tips appear live (delivered over a web socket)
* Being able to agree to disagree with a tip (also a POST)
* Being able to see a list of the tips sorted most agreeable to most
  disagreeable (obtained by a `GET`)

## Stubbing the backend

Think of a creative name for the application. I'm calling mine "tipsy". Then
use `cro stub` to stub a HTTP application. To keep it simple, we'll skip HTTPS
(and thus HTTP/2.0), but will include web sockets support.

```
$ cro stub http tipsy tipsy
Stubbing a HTTP Service 'tipsy' in 'tipsy'...

First, please provide a little more information.

Secure (HTTPS) (yes/no) [no]: n
Support HTTP/1.1 (yes/no) [yes]: y
Support HTTP/2.0 (yes/no) [no]: n
Support Web Sockets (yes/no) [no]: y
```

This creates a directory `tipsy`. Now let's go into it and check the stubbed
backend runs, using `cro run`:

```
$ cro run
▶ Starting tipsy (tipsy)
🔌 Endpoint HTTP will be at http://localhost:20000/
📓 tipsy Listening at http://localhost:20000
```

We can check it using `curl` or by visiting it in the browser:

```
$ curl http://localhost:20000
<h1> tipsy </h1>
```

I like to regularly commit as I work. So, I'll create a git repository, add
a `.gitignore` file (to ignore Perl 6 precompilation output), and commit the
stub.

```
$ git init .
Initialized empty Git repository in /home/jnthn/dev/cro/tipsy/.git/
jnthn@lviv:~/dev/cro/tipsy$ echo '.precomp/' > .gitignore
jnthn@lviv:~/dev/cro/tipsy$ git add .
jnthn@lviv:~/dev/cro/tipsy$ git commit -m "Stub tipsy backend"
[master (root-commit) ff1043a] Stub tipsy backend
 5 files changed, 99 insertions(+)
 create mode 100644 .cro.yml
 create mode 100644 .gitignore
 create mode 100644 META6.json
 create mode 100644 lib/Routes.pm6
 create mode 100644 service.p6
```

## Serving a static page

We'll now tweak our Cro stub application to serve a HTML page. We'll
create a `static` directory, where static content to serve will go.

```
mkdir static
```

In there, we'll put an `index.html` with the following context:

```
<html>
  <head>
    <title>Tipsy</title>
  </head>
  <body>
    <h1>Tipsy</h1>
  </body>
</html>
```

Then, we'll edit `lib/Routes.pm6` to get the `/` route to serve this file:

```
get -> {
    static 'static/index.html'
}
```

The `cro run` that we left running earlier should have automatically restarted
the service. Open the file in the browser to check that it's being served.

## Setting up the frontend build toolchain

Next up, we'll get set up for the frontend. First of all, we'll stub a
`package.json` file, which will contain our development and frontend
JavaScript dependencies. We use `npm init` and provide some answers:

```
$ npm init .
This utility will walk you through creating a package.json file.
It only covers the most common items, and tries to guess sensible defaults.

See `npm help json` for definitive documentation on these fields
and exactly what they do.

Use `npm install <pkg> --save` afterwards to install a package and
save it as a dependency in the package.json file.

Press ^C at any time to quit.
name: (tipsy) 
version: (1.0.0) 
description: Tipsy gives you tips at festivals
entry point: (index.js) 
test command: 
git repository: 
keywords: 
author: 
license: (ISC) 
About to write to /home/jnthn/dev/cro/tipsy/package.json:

{
  "name": "tipsy",
  "version": "1.0.0",
  "description": "Tipsy gives you tips at festivals",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC"
}


Is this ok? (yes) 
```

Next, let's install the webpack tool as a development dependency:

```
npm install --save-dev webpack
```

While that runs: what's webpack for? It helps out in various ways:

* It sets up compilation for us from modern JavaScript (with handy features
  like module imports, lambdas and `let` variable declarations) into a
  JavaScript version that works in web browsers
* It lets us use JavaScript modules, managed using the `npm` package manager,
  and have them concatenated into a single JavaScript file
* It can also help with CSS and image assets

Next up, we'll create a `webpack.config.js` in the root of the repository,
with the following contents:

```
const path = require('path');

module.exports = {
    entry: './frontend/index.js',
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'static/js')
    }
};
```

This means that it will take `frontend/index.js` as the root of the JavaScript
frontend part of our application, follow all of its dependencies, and build
them into a bundle that will be written out to `static/js/bundle.js`. Next,
let's create those locations. First, let's stub the output location; the
`.gitignore` both ignores the generated output as well as making sure the
directory exists (since git won't track empty directories).

```
$ mkdir static/js
$ echo '*' > static/js/.gitignore
```

Next, a stub `frontend/index.js`:

```
$ mkdir frontend
$ echo 'document.write("Hello from JS")' > frontend/index.js
```

Now, we'd like a way to run webpack conveniently from our local installation of
it. One way is to edit `package.json` and add an entry to the `scripts`
section:

```
  "scripts": {
    "build": "webpack",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
```

This can now be run with `npm run build`:

```
$ npm run build

> tipsy@1.0.0 build /home/jnthn/dev/cro/tipsy
> webpack

Hash: 142d15221600d8f7960f
Version: webpack 3.6.0
Time: 125ms
    Asset    Size  Chunks             Chunk Names
bundle.js  2.5 kB       0  [emitted]  main
   [0] ./frontend/index.js 32 bytes {0} [built]
```

## Serving and using the bundle

Next up, edit `static/index.html`, and just before the closing </body> tag
add:

```
<script src="js/bundle.js"></script>
```

Finally, we need to serve the JavaScript. Edit `lib/Routes.pm6` and add a new
route like this (which will serve anything under `static/js`, preparing us
for multiple bundles in the future should we need that):

```
get -> 'js', *@path {
    static 'static/js', @path
}
```

Refresh in the browser, and `Hello from JS` should appear on the page.

Last but not least, we need to ignore `node_modules`, and then can commit the
frontend stubbing:

```
$ echo 'node_modules/' >> .gitignore
$ git add .
$ git commit -m "Stub JavaScript application"
[master 199866c] Stub JavaScript application
 6 files changed, 40 insertions(+), 1 deletion(-)
 create mode 100644 frontend/index.js
 create mode 100644 package.json
 create mode 100644 static/index.html
 create mode 100644 webpack.config.js
```

## Starting to build the backend

To keep things simple, we'll build an in-memory model. There's all kinds of
ways we could factor it, but the key thing to keep in mind is that a web
application is a concurrent system, and in Cro requests are processed on a
thread pool. This means two requests may be processed at the same time!

To handle this, we'll use the OO::Monitors module. A monitor is like a class,
but it enforces mutual exclusion on its methods - that is, only one thread
may be inside the methods on a particular instance at a time. Thus, provided
we don't leak out our internal state (making defensive copies if we do have
to return parts of it), the state inside of the  monitor object is protected.

First, let's add `OO::Monitors` to our `META6.json` depends section, so that
part of the file looks like:

```
  "depends": [
    "Cro::HTTP",
    "Cro::WebSocket",
    "OO::Monitors"
  ],
```

To make sure you really have that module available, ask zef to install it if
it's missing:

```
$ zef install --deps-only .
```

We'll put our business logic in a separate module, `lib/Tipsy.pm6`, and write
some tests for it in `t/tipsy.t`. First, let's stub out the API for our
business/domain logic:

```
use OO::Monitors;

class Tip {
    has Int $.id;
    has Str $.tip;
    has Int $.agreed;
    has Int $.disagreed;
}

monitor Tipsy {
    method add-tip(Str $tip --> Nil) { ... }
    method agree(Int $tip-id --> Nil) { ... }
    method disagree(Int $tip-id --> Nil) { ... }
    method latest-tips(--> Supply) { ... }
    method top-tips(--> Supply) { ... }
}
```

Here, `Tip` is an immutable object representing a tip together with the number
of agrees and disagrees. The `Tipsy` class has a bunch of methods where we'll
implement the various operations. The first three are mutating operations. The
next, `latest-tips`, will be a `Supply` of Tip objects, emitting every time a
new tip is added. When it is first tapped, we will always emit the latest 50
tips. The `top-tips` method returns a Supply that will emit sorted lists of
the top 50 tips every time the rankings change. Don't try to remember all of
that, we'll come back to them one at a time.

Next up is to make this available to our routes. We could make the instance in
`Routes.pm6`, but that will make it hard to test our routes in isolation of
the business logic. Instead, we'll make the sub in Routes.pm6 take an instance
of the business logic object as parameter:

```
use Cro::HTTP::Router;
use Cro::HTTP::Router::WebSocket;
use Tipsy;

sub routes(Tipsy $tipsy) is export {
    route {
        get -> {
            static 'static/index.html'
        }
    ...
}
```

And then set it up in the `service.p6` entry point, by:

1. Using the module
2. Making an instance of it

The `service.p6` file will end up looking like this:

```
use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Routes;
use Tipsy;

my $tipsy = Tipsy.new;
my $application = routes($tipsy);

my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => %*ENV<TIPSY_HOST> ||
        die("Missing TIPSY_HOST in environment"),
    port => %*ENV<TIPSY_PORT> ||
        die("Missing TIPSY_PORT in environment"),
    :$application,
    after => [
        Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
    ]
);
$http.start;
say "Listening at http://%*ENV<TIPSY_HOST>:%*ENV<TIPSY_PORT>";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}
```

## Adding a tip and latest tips

Next, let's write tests for adding a tip and seeing it show up in the latest
tips. Here goes with `t/tipsy.t`:

```
use Tipsy;
use Test;

my $tipsy = Tipsy.new;
lives-ok { $tipsy.add-tip('The lamb kebabs are good!') },
    'Can add a tip';
lives-ok { $tipsy.add-tip('Not so keen on the fish burrito!') },
    'Can add another tip';
given $tipsy.latest-tips.head(2).list -> @tips {
    is @tips[0].tip, 'Not so keen on the fish burrito!',
        'Correct first tip retrieved on initial tap of latest-tips';
    is @tips[1].tip, 'The lamb kebabs are good!',
        'Correct second tip retrieved on initial tap of latest-tips';
}

react {
    whenever $tipsy.latest-tips.skip(2).head(1) {
        is .tip, 'Try the vanilla stout for sure',
            'Get new tips emitted live';
    }
    $tipsy.add-tip('Try the vanilla stout for sure');
}

done-testing;
```

The first part tests that we can add two tips, and that if we tap the `Supply`
of latest tips then we are given those two straight away. The second part is a
bit more involved: it checks that if we tap the latest tips Supply, and then a
new tip is added, then we will also be told about this new tip.

Now to make them pass! Here's the implementation in the `monitor`:

```
monitor Tipsy {
    has Int $!next-id = 1;
    has Tip %!tips-by-id{Int};
    has Supplier $!latest-tips = Supplier.new;

    method add-tip(Str $tip --> Nil) {
        my $id = $!next-id++;
        my $new-tip = Tip.new(:$id, :$tip);
        %!tips-by-id{$id} = $new-tip;
        start $!latest-tips.emit($new-tip);
    }

    method latest-tips(--> Supply) {
        my @latest-existing = %!tips-by-id.values.sort(-*.id).head(50);
        supply {
            whenever $!latest-tips {
                .emit;
            }
            .emit for @latest-existing;
        }
    }
    
    # The other unimplemented methods go here
}
```

We keep a counter of IDs to give each tip its own unique ID. We have a hash
mapping IDs to `Tip` objects. We then have a `Supplier` that we will use to
notify any interested parties when there are new tips.

The `add-tip` method's first 3 lines are straightforward, the final one is a
little curious: why the `start`? The answer is that, with supplies, the sender
pays for the cost of distributing the message, but we don't want to tie up the
monitor - which does mutual exclusion - with all of that work. So, we throw in
a `start` to dispatch the notifications asynchronously.

The `latest-tips` method also needs a little care. Remember that anything we
return from a `monitor` is not protected by the mutual exclusion. Thus, we
should make a copy of the latest existing tips outside of the `supply` block,
while the monitor is protected `%!tips-by-id`. Then, when the returned
`supply` block is tapped, we subscribe to the latest tips, and then emit each
of the latest existing ones.

And with these, our tests pass. Progress!

```
$ git add .
$ git commit -m "Implement first part of business logic"
[master 6e352c6] Implement first part of business logic
 6 files changed, 70 insertions(+), 4 deletions(-)
 create mode 100644 lib/Tipsy.pm6
 create mode 100644 t/tipsy.t
```

## Setting up React

Now it's time to get back to the frontend. We'll use React for that. React
gives us a virtual DOM, which we can rebuild every time something changes. It
then diffs it against the current real DOM, and applies the changes. This lets
us work in a more functional style. React components are written using JSX,
an XML-like syntax embedded in JavaScript. First we need to set up compiling
that. Here are the new development dependencies:

```
$ npm install --save-dev babel-loader babel-core babel-preset-es2015 babel-preset-react
```

Next, we need to create a `.babelrc` file, saying to use this react preset
(babel is the thing used to turn modern JavaScript into browser-compatible
JavaScript). It should simply contain:

```
{
  "presets" : ["es2015","react"]
}
```

Finally, the `webpack.config.js` needs updating to say to use this. After the
changes, it should look as follows:

```
const path = require('path');

module.exports = {
    entry: './frontend/index.js',
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'static/js')
    },
    module : {
        loaders : [
            {
                test: /\.js/,
                include: path.resolve(__dirname, 'frontend'),
                loader: 'babel-loader'
            }
        ]
    }
};
```

Try an `npm run build`. It should survive, though we aren't yet using any of
the new React support yet.

Next the build toolchain is set up, it's time to install the React modules we
will use in our frontend. Here goes:

```
$ npm install --save react react-dom
```

And with those, we can edit our `index.js` file to look like this:

```
import React from 'react';
import {render} from 'react-dom';

var App = () => <p>Hello React!</p>;
render(<App />, document.getElementById('app'));
```

And add a `div` tag with the ID `app` to our `index.html`:

```
<html>
  <head>
    <title>Tipsy</title>
  </head>
  <body>
    <h1>Tipsy</h1>
    <div id="app"></div>
    <script src="js/bundle.js"></script>
  </body>
</html>
```

Run `npm run build` again, refresh, and it should say `Hello React!`.

```
$ git add .
$ git commit -m "Setup react"
[master 0ffa260] Setup react
 5 files changed, 27 insertions(+), 1 deletion(-)
 create mode 100644 .babelrc
```

## Adding some components

Next, let's sketch out the UI a little more. Replace the existing `App`
component with this:

```
var SubmitTip = () => (
    <div>
        <h2>Got a tip?</h2>
        <div>
            <textarea rows="2" cols="100" maxlength="200" />
        </div>
        <input type="button" value="Add Tip" />
    </div>
);

var LatestTips = () => (
    <div>
        <h2>Latest Tips</h2>
        TODO
    </div>
);

var App = () => (
    <div>
        <SubmitTip />
        <LatestTips />
    </div>
);
```

Another `npm run build`, refresh, and it should show something that looks a
lot like one would expect from the UI. But how do we get data to populate the
UI? And how do we do stuff when the button is clicked? For that, we'll bring
in the final piece of the client side puzzle: Redux.

## Redux

There's [a good tutorial](http://redux.js.org/) on Redux on its site, and I
won't try and repeat it all here, but I'll try to summarize what Redux does.
React gives us a way to render a virtual DOM each time something changes. To
make that useful, we need some kind of object containing the current state
that should be rendered onto the UI. Redux is a container for that state, and
gets us to organize changes to it using reducers. That is to say, we never
really update state, we just produce a new one derived from the current one,
plus an action.

First, let's add the `redux` and related dependencies.

```
$ npm install --save redux redux-thunk react-redux
```

Next up, we need to define some actions. Actions correspond to state changes
on the page. We'll create just two for now:

* `CHANGE_TIP_TEXT` - when the text of the tip the user is typing changes
* `ADD_TIP` - when the Add Tip button is pressed

In a `frontend/actions.js` file, we do this:

```
export const CHANGE_TIP_TEXT = 'CHANGE_TIP_TEXT';
export const ADD_TIP = 'ADD_TIP';

export function changeTipText(text) {
    return { type: CHANGE_TIP_TEXT, text };
}
export function addTip() {
    return { type: ADD_TIP };
}
```

The constants are names of actions, and the functions are known as "action
creators": they create an object with a `type` property and, optionally, some
data.

Next, we need a reducer. Reducers take current state, and calculate and return
a new state. They never mutate the state and never do any side-effects (such
as network I/O). They are pure calculation. Our state will, for now, be very
simple: just the content of the text box.

Writing reducers is much more convenient when we have the upcoming spread
operator in JavaScript; it's a prefix `...`, and works much like Perl 6's
prefix `|` operator for flattening. Since we already have a build toolchain,
we can add it by installing another syntax transform:

```
npm install --save-dev babel-plugin-transform-object-rest-spread
```

And adding it to our `.babelrc`:

```
{
    "presets" : ["es2015","react"],
    "plugins" : ["transform-object-rest-spread"]
}
```

With that done, here's our reducer, placed in `frontend/reducer.js`:

```
import ActionTypes from './actions';

const initialState = {
    tipText: ''
};
export function tipsyReducer(state = initialState, action) {
    switch (action.type) {
        case ActionTypes.CHANGE_TIP_TEXT:
            return { ...state, tipText: action.text };
        case ActionTypes.ADD_TIP:
            return { ...state, tipText: '' };
        default:
            return state;
    }
}
```

Now it's time to wire it up to React. The overall flow will be:

1. Something happens on the UI (text changed, add tip button pressed)
2. An action object is created
3. It's passed into the reducer, which produces a new state
4. The new state is turned into properties, which are then used to build up a
   React virtual DOM
5. React takes care of applying any updates to the real DOM, thus reflecting
   our changes

Back in `frontend/index.js`, we'll import our actions and reducer, together
with some bits from the `redux` and `react-redux` libraries:

```
import { createStore } from 'redux';
import { Provider, connect } from 'react-redux';
import * as Actions from './actions';
import { tipsyReducer } from './reducer';
```

Next up, we'll create a Redux store, which is the thing that holds the latest
version of the state produced by the reducer. We create it simply by passing
our reducer to `createStore`:

```
let store = createStore(tipsyReducer);
````

Next up, we need to map the state from the store into properties that will be
available in our React components, and also produce some functions that will
also be made available in those properties, and will dispatch actions.

```
function mapProps(state) {
    return state;
}
function mapDispatch(dispatch) {
    return {
        onChangeTipText: text => dispatch(Actions.changeTipText(text)),
        onAddTip: text => dispatch(Actions.addTip())
    };
}
```

With those ready, we can complete the integration of Redux with React, which
looks like this:

```
let ConnectedApp = connect(mapProps, mapDispatch)(App);
render(
    <Provider store={store}>
        <ConnectedApp />
    </Provider>,
    document.getElementById('app'));
```

The `connect` function makes the properties from the state in the store
available to the `App` React component, and wrapping it in `Provider` makes
the state from the `store` available in order for that to happen.

Last but not least, we can update our components:

```
var SubmitTip = props => (
    <div>
        <h2>Got a tip?</h2>
        <div>
            <textarea rows="2" cols="100" maxLength="200"
                value={props.tipText}
                onChange={e => props.onChangeTipText(e.target.value)} />
        </div>
        <input type="button" value="Add Tip" onClick={props.onAddTip} />
    </div>
);

var App = props => (
    <div>
        <SubmitTip tipText={props.tipText}
            onChangeTipText={props.onChangeTipText}
            onAddTip={props.onAddTip} />
        <LatestTips />
    </div>
);
```

After `npm run build`, and a refresh in the browser, we should notice that
hitting the Add Tip button after typing will clear the text box. Our actions
and reducer are running. Phew!

For completeness, here is the entire `frontend/index.js` at this stage:

```
import React from 'react';
import { render } from 'react-dom';
import { createStore } from 'redux';
import { Provider, connect } from 'react-redux';
import * as Actions from './actions';
import { tipsyReducer } from './reducer';

var SubmitTip = props => (
    <div>
        <h2>Got a tip?</h2>
        <div>
            <textarea rows="2" cols="100" maxLength="200"
                value={props.tipText}
                onChange={e => props.onChangeTipText(e.target.value)} />
        </div>
        <input type="button" value="Add Tip" onClick={props.onAddTip} />
    </div>
);

var LatestTips = () => (
    <div>
        <h2>Latest Tips</h2>
        TODO
    </div>
);

var App = props => (
    <div>
        <SubmitTip tipText={props.tipText}
            onChangeTipText={props.onChangeTipText}
            onAddTip={props.onAddTip} />
        <LatestTips />
    </div>
);

function mapProps(state) {
    return state;
}
function mapDispatch(dispatch) {
    return {
        onChangeTipText: text => dispatch(Actions.changeTipText(text)),
        onAddTip: text => dispatch(Actions.addTip())
    };
}

let store = createStore(tipsyReducer);
let ConnectedApp = connect(mapProps, mapDispatch)(App);
render(
    <Provider store={store}>
        <ConnectedApp />
    </Provider>,
    document.getElementById('app'));
```

It's commit time again.

```
$ git add .
$ git commit -m "Wire up Redux"
[master 3478433] Wire up Redux
 5 files changed, 83 insertions(+), 7 deletions(-)
 create mode 100644 frontend/actions.js
 rewrite frontend/index.js (81%)
 create mode 100644 frontend/reducer.js
```

## POSTing to the backend

Finally, it's time to get adding a tip in the frontend calling the backend!
We'll need to do two things:

1. Write a POST handler in the Cro backend
2. Find a way to have our Redux action result in a POST

First for the Cro part. In `lib/Routes.pm6` we add the following route
implementation:

```
post -> 'tips' {
    request-body -> (:$text) {
        $tipsy.add-tip($text);
        response.status = 204;
    }
}
``` 

Next up, the JavaScript part. The question is where to put the network bit?
Our reducer should be pure. The answer is the `redux-thunk` module that we
installed earlier, but didn't yet use. This allows us to write action creators
that return a function. This function will be passed the dispatcher, and it
can call it to dispatch actions. Typically, we will dispatch one action when an
asynchronous operation starts, which we can use to indicate that on the UI,
and a further one once it has completed, so we can again indicate that the
operation completed in the UI.

First, let's setup `react-thunk`, which is a piece of middleware. Back in
`frontend/index.js`, add:

```
import thunkMiddleware from 'redux-thunk';
```

And then change:

```
import { createStore } from 'redux';
```

To also import `applyMiddleware`:

```
import { createStore, applyMiddleware } from 'redux';
```

Finally, change:

```
let store = createStore(tipsyReducer);
```

To apply the middlware also:

```
let store = createStore(tipsyReducer, applyMiddleware(thunkMiddleware));
```

Next, in `frontend/actions.js`, we'll refactor the add tip action creator
function to be a thunk action:

```
export function addTip() {
    return dispatch => {
        dispatch({ type: ADD_TIP });
    };
}
```

Note that this doesn't yet change anything; build it and the behavior should
be just the same. Now that we've done this, however, we can see that it will
be possible to do this dispatch in a callback after the network operation.

There's, of course, dozens of good ways to deal with asynchronous operations
in JavaScript, and if you are seriously building single page applications I
strongly recommend looking into using a promise library. There's also Redux
middleware that will integrate with that. For now, we'll do the simplest
possible thing: use jQuery and a callback. First, let's add jQuery as a
dependency:

```
$ npm install --save jquery
```

Then we'll import it in `frontend/actions.js`:

```
import $ from 'jquery';
```

And do the POST to the backend:

```
export function addTip() {
    return (dispatch, getState) => {
        $.ajax({
            url: '/tips',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({ text: getState().tipText }),
            success: () => dispatch({ type: ADD_TIP })
        });
    };
}
```

Reload it, maybe open your browser's development tools (F12 usually), flip to
the Network tap, and click Add Tip. All being well, you'll observe the request
was made and it produced a 204 response. Alternatively, you may like to stop
the `cro run` and instead do `cro trace`; type a message, click Add Tip again,
and you should see the request body dumped in the trace output.

```
...
65 63 74 69 6f 6e 3a 20 6b 65 65 70 2d 61 6c 69  ection: keep-ali
76 65 0d 0a 0d 0a 7b 22 74 65 78 74 22 3a 22 74  ve....{"text":"t
72 79 20 74 68 65 20 62 65 65 66 22 7d           ry the beef"}
```

## The latest tips websocket

There's a variety of ways that we could write up the websocket, but we'll use
`redux-websocket-action`. This allows us to send Redux actions over the
websocket to the client, which is neat (although, unfortunately, does mean we
are coupling our backend to the use of this library in the frontend, which is
worth some questioning).

First, let's install the library in the frontend:

```
$ npm install --save redux-websocket-action
```

Over in `index.js`, we import it:

```
import WSAction from 'redux-websocket-action';
```

And set it up, like this:

```
let host = window.location.host;
let wsAction = new WSAction(store, 'ws://' + host + '/latest-tips', {
    retryCount:3,
    reconnectInterval: 3
});
wsAction.start();
```

Over in `frontend/actions.js`, we'll add one more action type (but no action
creation function, as it will originate on the server):

```
export const LATEST_TIP = 'LATEST_TIP';
```

Then we'll update our reducer, to prepend each incoming tip to a list of
latest tips, so `frontend/reducers.js` ends up as:

```
import * as ActionTypes from './actions';

const initialState = {
    tipText: '',
    latestTips: []
};
export function tipsyReducer(state = initialState, action) {
    switch (action.type) {
        case ActionTypes.CHANGE_TIP_TEXT:
            return { ...state, tipText: action.text };
        case ActionTypes.ADD_TIP:
            return { ...state, tipText: '' };
        case ActionTypes.LATEST_TIP: {
            let tip = { id: action.id, text: action.text };
            return {
                ...state,
                latestTips: [tip, ...state.latestTips]
            };
        }
        default:
            return state;
    }
}
```

And then update the React components in `frontend/index.js` to render the
latest tips:

```
var LatestTips = props => (
    <div>
        <h2>Latest Tips</h2>
        <ul>
        {props.tips.map(t => <li key={t.id}>{t.text}</li>)}
        </ul>
    </div>
);

var App = props => (
    <div>
        <SubmitTip tipText={props.tipText}
            onChangeTipText={props.onChangeTipText}
            onAddTip={props.onAddTip} />
        <LatestTips tips={props.latestTips} />
    </div>
);
```

`App` is updated simply to pass the tips to the `LatestTips` component. And
with that, the client-side additions are done.

Now for the backend, which is just a single addition in `Routes.pm6`. We clear
out the websocket stub that was generated for us, and replace it with code to
take the `latest-tips` Supply from the `Tipsy` business logic object, turn the
events into appropriate JSON, and emit them:

```
get -> 'latest-tips' {
    web-socket -> $incoming {
        supply whenever $tipsy.latest-tips -> $tip {
            emit to-json {
                WS_ACTION => True,
                action => {
                    type => 'LATEST_TIP',
                    id => $tip.id,
                    text => $tip.tip
                }
            }
        }
    }
}
```

The outer hash is the "envelope" for `redux-websocket-action`, which tells it
to pay attention to the message and dispatch its `action` property as a Redux
action.

Reload it in the browser. Add a tip. See it show up. Open a second tab with
the application. You'll see it shows the first tip. Add a second tip. Flip
back to the first tab, and you'll see that tip magically showed up there too.
We're now successfully sharing out the tips over the web socket. Hurrah! That
calls for a commit.

## Agree and disagree

We've spent a lot of time setting up the client-side infrastructure. Now it's
in place, however, adding further features is a far quicker process. Let's
round off the tutorial by implementing the Agree/Disagree feature (links to
let the user indicate agreement/disagreement with the tips), and showing the
list of top tips.

Let's start out in the very backend, by writing tests for these new features
in the business logic object. We'll add these tests to `t/tipsy.t`:

```
given $tipsy.latest-tips.head(3).list -> @tips {
    $tipsy.agree(@tips[0].id) for ^3;
    $tipsy.agree(@tips[1].id) for ^4;
    $tipsy.disagree(@tips[1].id) for ^10;
    $tipsy.agree(@tips[2].id) for ^2;
}
given $tipsy.top-tips.head(1).list[0] {
    is .[0].tip, 'Try the vanilla stout for sure',
        'Most agreeable tip first';
    is .[1].tip, 'The lamb kebabs are good!',
        'Next most agreeable tip second';
    is .[2].tip, 'Not so keen on the fish burrito!',
        'Least agreeable tip third';
}
throws-like { $tipsy.agree(99999) }, X::Tipsy::NoSuchId,
    'Correct exception on no such tip';
```

The first part just adds some agreement and disagreement on the tips (they are
sorted latest first). Next, we use the `top-tips` Supply and grab the first
thing it emits (or should emit, at least), which is the current ordering at
the point we tap the Supply. It checks that ordering is correct. A final test
checks that for unrecognized IDs, we throw an exception.

Here's the new exception type:

```
class X::Tipsy::NoSuchId is Exception {
    has $.id;
    method message() { "No tip with ID '$!id'" }
}
```

Next up, we'll give the `Tip` class some methods that produce a new version of
the `Tip` object with agreed or disagreed bumped one higher (we keep these
instances immutable, since we share them outside of our `monitor`):

```
class Tip {
    has Int $.id is required;
    has Str $.tip is required;
    has Int $.agreed = 0;
    has Int $.disagreed = 0;

    method agree() {
        self.clone(agreed => $!agreed + 1)
    }

    method disagree() {
        self.clone(disagreed => $!disagreed + 1)
    }
}
```

The `agree` and `disagree` methods are easy enough:

```
method agree(Int $tip-id --> Nil) {
    with %!tips-by-id{$tip-id} -> $tip-ref is rw {
        $tip-ref .= agree;
    }
    else {
        X::Tipsy::NoSuchId.new(id => $tip-id).throw;
    }
}

method disagree(Int $tip-id --> Nil) {
    with %!tips-by-id{$tip-id} -> $tip-ref is rw {
        $tip-ref .= disagree;
    }
    else {
        X::Tipsy::NoSuchId.new(id => $tip-id).throw;
    }
}
```

Hm, actually that's quite a bit of similarity. Let's use a private method to
factor it out:

```
method agree(Int $tip-id --> Nil) {
    self!with-tip: $tip-id, -> $tip-ref is rw {
        $tip-ref .= agree;
    }
}

method disagree(Int $tip-id --> Nil) {
    self!with-tip: $tip-id, -> $tip-ref is rw {
        $tip-ref .= disagree;
    }
}   
        
method !with-tip(Int $tip-id, &operation --> Nil) {
    with %!tips-by-id{$tip-id} -> $tip-ref is rw {
        operation($tip-ref)
    }
    else {
        X::Tipsy::NoSuchId.new(id => $tip-id).throw;
    }
}
```

Finally, here's our first attempt at the `top-tips` method:

```
method top-tips(--> Supply) { 
    my @top-tips = %!tips-by-id.values
        .sort({ .disagreed - .agreed })
        .head(50);
    supply {
        emit @top-tips;
    }
}
```

It passes the tests, and yet...something is missing. It's meant to emit an
updated sorted list of tips every time there's either a new tip or a tip is
agreed or disagreed with. Let's add some tests for that also:

```
my $new-tip-id;
react {
    whenever $tipsy.top-tips.skip(1).head(1) {
        is .[0].tip, 'Try the vanilla stout for sure',
            'After adding a tip, correct order (1)';
        is .[1].tip, 'The lamb kebabs are good!',
            'After adding a tip, correct order (2)';
        is .[2].tip, 'The pau bahji is super spicy',
            'After adding a tip, correct order (3)';
        is .[3].tip, 'Not so keen on the fish burrito!',
            'After adding a tip, correct order (4)';
        $new-tip-id = .[2].id;
    }
    $tipsy.add-tip('The pau bahji is super spicy');
}
ok $new-tip-id, 'New tip ID seen in top sorted tips';

react {
    whenever $tipsy.top-tips.skip(5).head(1) {
        is .[0].tip, 'The pau bahji is super spicy',
            'After agrees, order updated';
    }
    $tipsy.agree($new-tip-id) for ^5;
}
```

To have this update, we need a `Supplier` that we can emit on to indicate a
change to the agree/disagree counts.

```
has Supplier $!tip-change = Supplier.new;
```

And to emit on it (easy after the factoring out earlier):

```
method !with-tip(Int $tip-id, &operation --> Nil) {
    with %!tips-by-id{$tip-id} -> $tip-ref is rw {
        operation($tip-ref);
        start $!tip-change.emit($tip-ref<>);
    }
    else {
        X::Tipsy::NoSuchId.new(id => $tip-id).throw;
    }
}
```

Finally, to update the `top-tips` method. There's a few ways we could do this,
but the easiest way to be sure we're safe is to make sure the `Supply` keeps
its own local state, which it can protect (again, remember that since the
`supply` block is returned from, and lives beyond, the method, it is not going
to be protected by the monitor).

```
method top-tips(--> Supply) {
    my %initial-tips = %!tips-by-id;
    supply {
        my %current-tips = %initial-tips;
        sub emit-latest-sorted() {
            emit [%current-tips.values.sort({ .disagreed - .agreed }).head(50)]
        }
        whenever Supply.merge($!latest-tips.Supply, $!tip-change.Supply) {
            %current-tips{.id} = $_;
            emit-latest-sorted;
        }
        emit-latest-sorted;
    }
}
```

With that done, it's time to expose this functionality to the outside world by
updating `lib/Routes.pm6`. Its job is to map the business logic onto HTTP. The
only thing we need to watch out for is to turn the "no such ID" exceptions
into the appropriate HTTP response, which is a 404 Not Found. Otherwise, we'd
send back 500 Internal Server Error, which is wrong because it's not the
server's fault that the client sent some bogus ID. Here goes:

```
post -> 'tips', Int $id, 'agree' {
    $tipsy.agree($id);
    response.status = 204;
    CATCH {
        when X::Tipsy::NoSuchId {
            not-found;
        }
    }
}

post -> 'tips', Int $id, 'disagree' {
    $tipsy.disagree($id);
    response.status = 204;
    CATCH {
        when X::Tipsy::NoSuchId {
            not-found;
        }
    }
}
```

The final step in the backend is to map the top tips out to another web
socket:

```
get -> 'top-tips' {
    web-socket -> $incoming {
        supply whenever $tipsy.top-tips -> @tips {
            emit to-json {
                WS_ACTION => True,
                action => {
                    type => 'UPDATE_TOP_TIPS',
                    tips => [@tips.map: -> $tip {
                        {
                            id => $tip.id,
                            text => $tip.tip,
                            agreed => $tip.agreed,
                            disagreed => $tip.disagreed
                        }
                    }]
                }
            }
        }
    }
}
```

Now for the frontend. In `frontend/actions.js`, we'll add three new action
type constants:

```
export const UPDATE_TOP_TIPS = 'UPDATE_TOP_TIPS';
export const AGREE = 'AGREE';
export const DISAGREE = 'DISAGREE';
```

And then two new action creators (`UPDATE_TOP_TIPS` doesn't need one, as it
comes from the server):

```
export function agree(id) {
    return dispatch => {
        $.ajax({
            url: '/tips/' + id + '/agree',
            type: 'POST',
            success: () => dispatch({ type: AGREE, id })
        });
    };
}
export function disagree(id) {
    return dispatch => {
        $.ajax({
            url: '/tips/' + id + '/disagree',
            type: 'POST',
            success: () => dispatch({ type: DISAGREE, id })
        });
    };
}
```

In the reducer, we'll tweak the initial state to have an empty set of top
tips:

```
const initialState = {
    tipText: '',
    latestTips: [],
    topTips: []
};
```

And then add an extra case statement to handle the new update action (we don't
need to do anything much on agree/disagree, though in a real application we'd
want to give some user feedback that their vote was counted):

```
case ActionTypes.UPDATE_TOP_TIPS:
    return {
        ...state,
        topTips: action.tips
    };
```

Next we need to get the second web socket connected up. That's just a little
refactor away in `frontend/index.js`:

```
['latest-tips', 'top-tips'].forEach(endpoint => {
    let host = window.location.host;
    let wsAction = new WSAction(store, 'ws://' + host + '/' + endpoint, {
        retryCount:3,
        reconnectInterval: 3
    });
    wsAction.start();
});
```

Next, we'll update the dispatch to props map, to incldue our new agree and
disagree actions:

```
function mapDispatch(dispatch) {
    return {
        onChangeTipText: text => dispatch(Actions.changeTipText(text)),
        onAddTip: text => dispatch(Actions.addTip()),
        onAgree: id => dispatch(Actions.agree(id)),
        onDisagree: id => dispatch(Actions.disagree(id)),
    };
}
```

Next up, we'll factor out showing a tip to a component that we can reuse in
both the latest tips and top tips, which includes links to agree or disagree:

```
var Tip = props => (
    <li>
        {props.text} [<a href="#" onClick={() => props.onAgree(props.id)}>Agree</a>]
        [<a href="#" onClick={() => props.onDisagree(props.id)}>Disagree</a>]
    </li>
);
```

And then showing a list of tips, with a heading:

```
var TipList = props => (
    <div>
        <h2>{props.heading}</h2>
        <ul>
        {props.tips.map(t => <Tip key={t.id} {...props} {...t} />)}
        </ul>
    </div>
);
```

Finally, the `App` component becomes:

```
var App = props => (
    <div>
        <SubmitTip tipText={props.tipText}
            onChangeTipText={props.onChangeTipText}
            onAddTip={props.onAddTip} />
        <TipList heading="Latest Tips" tips={props.latestTips}
            onAgree={props.onAgree} onDisagree={props.onDisagree} />
        <TipList heading="Top Tips" tips={props.topTips}
            onAgree={props.onAgree} onDisagree={props.onDisagree} />
    </div>
);
```

And there we have it. `npm run build`, refresh, and give it a spin. Clicking
agree of disagree in either list ends up with the sort order in the Top Tips
list changing to reflect the votes.

At last, we're done.

```
$ git commit -m "Add agree/disagree feature" .
[master 5d792bc] Add agree/disagree feature
 6 files changed, 188 insertions(+), 18 deletions(-)
```

## Summing up

In this tutorial we've gone from zero to reactive single page application. The
frontend is written in modern ES6 using React and Redux. The backend is in
Perl 6, using Cro. They communicate using both HTTP and web sockets. And both
declare their dependencies, so getting started for a new developer is just a
case of:

```
zef install --deps-only .
npm install .
npm run build
cro run
```

One again, the [code is available](https://github.com/croservices/sample-app-spa-react)
with the commit history described during this tutorial.
