import { connect } from 'react-redux';
import App from './components';
import * as Actions from './actions';

function mapProps(state) {
    return state;
}

function mapDispatch(dispatch) {
    return {
        onCreateNew: () => dispatch(Actions.createNew())
    }
}

let OverviewApp = connect(mapProps, mapDispatch)(App);
export default OverviewApp;
