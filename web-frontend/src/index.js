import React from 'react';
import ReactDOM from 'react-dom';
import { Navbar, Nav, NavItem } from 'react-bootstrap';

var MainArea = props => (
    <div>
      <Navigation />
      <div className="container">
      </div>
    </div>
);

var Navigation = props => (
    <Navbar>
      <Navbar.Header>
        <Navbar.Brand>
          <a href="/">Cro Development Tool</a>
        </Navbar.Brand>
        </Navbar.Header>
      <Nav>
        <NavItem eventKey={1} href="#">Dashboard</NavItem>
        <NavItem eventKey={2} href="#">Stub Service</NavItem>
        <NavItem eventKey={3} href="http://cro.services/docs">Documentation</NavItem>
      </Nav>
    </Navbar>
);

ReactDOM.render(
    <MainArea />,
    document.getElementById('app')
);
