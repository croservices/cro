import { connect } from 'react-redux';
import App from './components';
import * as Actions from './actions';

function mapProps(state) {
    return state;
}

function mapDispatch(dispatch) {
    return {
        onSelectChannel: id => dispatch(Actions.logsSelectChannel(id))
    }
}

let LogsApp = connect(mapProps, mapDispatch)(App);
export default LogsApp;
