import { connect } from 'react-redux';
import App from './components';
import * as Actions from './actions';

function mapProps(state) {
    return state;
}

function mapDispatch(dispatch) {
    return {
        onStubSelect: index => dispatch(Actions.stubSelect(index))
    }
}

let StubApp = connect(mapProps, mapDispatch)(App);
export default StubApp;
