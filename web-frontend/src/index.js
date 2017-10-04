import React from 'react';
import ReactDOM from 'react-dom';
import { createStore, combineReducers } from 'redux';
import { Provider } from 'react-redux';
import { Router, Route, browserHistory } from 'react-router';
import { syncHistoryWithStore, routerReducer } from 'react-router-redux';
import { Navbar, Nav, NavItem } from 'react-bootstrap';

// Build up reducers from the various components.
const store = createStore(combineReducers({
   routing: routerReducer
}));

// Set up history.
const history = syncHistoryWithStore(browserHistory, store);

// Temporary components, to move out later
var Overview = props => (
    <div id="dashboard" className="container">
      Dashboard goes here
    </div>
);
var Stub = props => (
    <div id="stub" className="container">
      Stub service UI goes here
    </div>
);
var Logs = props => (
    <div id="logs" className="container">
      Logs and Traces go here
    </div>
);

var Navigation = props => (
    <Navbar>
      <Navbar.Header>
        <Navbar.Brand>
          <a href="#" onClick={() => browserHistory.push("/")}>Cro Development Tool</a>
        </Navbar.Brand>
        </Navbar.Header>
      <Nav>
        <NavItem onClick={() => browserHistory.push("/")}>Overview</NavItem>
        <NavItem onClick={() => browserHistory.push("/stub")}>Stub Service</NavItem>
        <NavItem onClick={() => browserHistory.push("/logs")}>Logs and Traces</NavItem>
      </Nav>
    </Navbar>
);

ReactDOM.render(
    <Provider store={store}>
      <div>
        <Navigation />
        <div className="container content">
          <div className="row">
            <div className="col-sm-4">
                Service list
            </div>
            <div className="col-sm-8">
                <Router history={history}>
                <Route path="/" component={Overview} />
                <Route path="/stub" component={Stub} />
                <Route path="/logs" component={Logs} />
                </Router>
            </div>
          </div>
        </div>
      </div>
    </Provider>,
    document.getElementById('app')
);
