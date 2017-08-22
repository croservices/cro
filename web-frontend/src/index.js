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
var Dashboard = props => (
    <div className="container">
      Dashboard goes here
    </div>
);
var Stub = props => (
    <div className="container">
      Stub service UI goes here
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
        <NavItem onClick={() => browserHistory.push("/")}>Dashboard</NavItem>
        <NavItem onClick={() => browserHistory.push("/stub")}>Stub Service</NavItem>
        <NavItem href="http://cro.services/docs">Documentation</NavItem>
      </Nav>
    </Navbar>
);

ReactDOM.render(
    <Provider store={store}>
	  <div>
      <Navigation />
	  <Router history={history}>
        <Route path="/" component={Dashboard} />
        <Route path="/stub" component={Stub} />
      </Router>
      </div>
    </Provider>,
    document.getElementById('app')
);
