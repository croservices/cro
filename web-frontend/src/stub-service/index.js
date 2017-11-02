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
        onChangePathText: text => dispatch(Actions.stubChangePathText(text)),
        onChangeNameText: text => dispatch(Actions.stubChangeNameText(text)),
        onChangeOption: (id, value) => dispatch(Actions.stubChangeOption(id, value)),
        onStubSent: (id, name, path, type, opts) => dispatch(Actions.stubStub(id, name, path, type, opts)),
        stubUnmount: () => dispatch(Actions.stubUnmount())
    }
}

let StubApp = connect(mapProps, mapDispatch)(App);
export default StubApp;
