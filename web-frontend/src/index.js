import { connect } from 'react-redux';
import React from 'react';
import ReactDOM from 'react-dom';
import WSAction from 'redux-websocket-action';
import ServiceListApp from './service-list/index';
import serviceListReducer from './service-list/reducer';
import StubApp from './stub-service/index';
import stubReducer from './stub-service/reducer';
import LogsApp from './logs/index';
import logsReducer from './logs/reducer';
import OverviewApp from './overview/index';
import overviewReducer from './overview/reducer';
import LinkApp from './link/index';
import linkReducer from './link/reducer';
import thunkMiddleware from 'redux-thunk';
import { Navbar, Nav, NavItem } from 'react-bootstrap';
import { Provider } from 'react-redux';
import { Router, Route, browserHistory } from 'react-router';
import { createStore, applyMiddleware, combineReducers } from 'redux';
import { syncHistoryWithStore, routerReducer } from 'react-router-redux';

// Build up reducers from the various components.
const store = createStore(combineReducers({
    routing: routerReducer,
    serviceListReducer,
    stubReducer,
    logsReducer,
    overviewReducer,
    linkReducer
}), applyMiddleware(thunkMiddleware));
// Set up history.
const history = syncHistoryWithStore(browserHistory, store);

['overview-road', 'services-road', 'stub-road', 'logs-road', 'link-road'].forEach(endpoint => {
    let host = window.location.host;
    let wsAction = new WSAction(store, 'ws://' + host + '/' + endpoint, {
        retryCount: 3,
        reconnectInterval: 3
    });
    wsAction.start();
});

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
              <ServiceListApp history={history} />
            </div>
            <div className="col-sm-8">
              <Router history={history}>
                <Route path="/" component={OverviewApp} />
                <Route path="/stub" component={StubApp} />
                <Route path="/logs" component={LogsApp} />
                <Route path="/links/:serviceid" component={LinkApp} />
              </Router>
            </div>
          </div>
        </div>
      </div>
    </Provider>,
    document.getElementById('app')
);
