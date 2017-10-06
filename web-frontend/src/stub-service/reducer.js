import * as ActionTypes from './actions';

const initialState = {
    templates: [],
    current: null
};

export default function stubReducer(state = initialState, action) {
    console.log("Stub reducer");
    console.log(action.type);
    switch (action.type) {
    case ActionTypes.STUB_TEMPLATES:
        return { ...state, templates: action.templates, current: action.templates[0] }
    case ActionTypes.STUB_SELECT:
        return { ...state, current: state.templates[action.index] }
    default:
        return state;
    }
}
