import * as ActionTypes from './actions';

const initialState = {
    templates: [],
    options: [],
    current: null,
    idText: ''
};

export default function stubReducer(state = initialState, action) {
    switch (action.type) {
    case ActionTypes.STUB_TEMPLATES:
        var options = new Map();
        action.templates[0].options.map(o => {
            options.set(o[0], o[3]);
        });
        return { ...state,
                 templates: action.templates,
                 current: action.templates[0],
                 options }
    case ActionTypes.STUB_SELECT:
        var options = new Map();
        state.templates[action.index].options.map(o => {
            options.set(o[0], o[3]);
        });
        return { ...state, current: state.templates[action.index], options }
    case ActionTypes.STUB_CHANGE_OPTION:
        var options = state.options;
        options.set(action.id, action.value);
        return { ...state, options }
    case ActionTypes.STUB_CHANGE_ID_TEXT:
        return { ...state, idText: action.text }
    case ActionTypes.STUB_STUB:
        return { ...state, idText: '' }
    default:
        return state;
    }
}
