import { connect } from 'react-redux';
import App from './components';
import * as Actions from './actions';
import * as LogsActions from '../logs/actions';
import * as LinkActions from '../link/actions';

function mapProps(state) {
    return state;
}

function mapDispatch(dispatch) {
    return {
        onServiceStop: id => dispatch(Actions.serviceStop(id)),
        onServiceStart: id => dispatch(Actions.serviceStart(id)),
        onServiceRestart: id => dispatch(Actions.serviceRestart(id)),
        onServiceTraceFlip: (id, checked) => dispatch(Actions.serviceTraceFlip(id, checked)),
        onGotoLogs: id => dispatch(LogsActions.serviceGotoLogs(id)),
        onGotoLinks: id => dispatch(LinkActions.linkGotoLinks(id))
    }
}

let ServiceListApp = connect(mapProps, mapDispatch)(App);
export default ServiceListApp;
