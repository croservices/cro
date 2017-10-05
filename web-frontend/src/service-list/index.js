import React from 'react';
import { connect } from 'react-redux';

function mapProps(state) {
    return state;
}

function mapDispatch(dispatch) {
    return {}
}

var App = props => (
        <div>
        {Array.from(props.serviceListReducer.services).map(elem => elem[1].name)}
        </div>
);

let ServiceListApp = connect(mapProps, mapDispatch)(App);
export default ServiceListApp;
