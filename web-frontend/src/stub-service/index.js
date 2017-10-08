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
        onStub: (type, id, opts) => dispatch(Actions.stubStub(type, id, opts))
    }
}

let StubApp = connect(mapProps, mapDispatch)(App);
export default StubApp;
