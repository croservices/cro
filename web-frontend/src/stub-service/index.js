import { connect } from 'react-redux';
import App from './components';
import * as Actions from './actions';

function mapProps(state) {
    return state;
}

function mapDispatch(dispatch) {
    return {
        onStubSelect: index => dispatch(Actions.stubSelect(index)),
        onChangeIdText: text => dispatch(Actions.stubChangeIdText(text)),
        onChangeOption: (id, value) => dispatch(Actions.stubChangeOption(id, value)),
        onStubSent: (id, type, opts) => dispatch(Actions.stubStub(id, type, opts))
    }
}

let StubApp = connect(mapProps, mapDispatch)(App);
export default StubApp;
