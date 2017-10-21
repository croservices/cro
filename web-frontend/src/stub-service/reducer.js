import * as ActionTypes from './actions';

const initialState = {
    templates: [],
    current: null,
    idText: '',
    notify: '',
    option_errors: [],
    stub_errors: []
};

export default function stubReducer(state = initialState, action) {
    switch (action.type) {
    case ActionTypes.STUB_TEMPLATES:
        var templates = action.templates;
        templates.sort(function(a, b) {
            return a.id.localeCompare(b.id)
        });
        return { ...state, templates,
                 current: action.templates[0] }
    case ActionTypes.STUB_STUBBED:
        return { ...state, stub_errors: '',
                 option_errors: '', idText: '',
                 notify: 'Successfully stubbed!' }
    case ActionTypes.STUB_OPTIONS_ERROR_OCCURED:
        return { ...state, notify: 'Error occured with options:', option_errors: action.errors }
    case ActionTypes.STUB_STUB_ERROR_OCCURED:
        return { ...state, notify: 'Error occured during stubbing:', stub_errors: action.errors }

    case ActionTypes.STUB_SELECT:
        return { ...state, current: state.templates[action.index], notify: '' }
    case ActionTypes.STUB_CHANGE_ID_TEXT:
        return { ...state, idText: action.text }
    case ActionTypes.STUB_CHANGE_OPTION:
        var opts = state.current.options;
        for (var i = 0; i < opts.length; i++) {
            if (opts[i][0] == action.id) {
                opts[i][3] = action.value;
            }
        }
        state.current.options = opts;
        return { ...state, notify: '', option_errors: '', stub_errors: '' }
    case ActionTypes.STUB_STUB_SENT:
        return { ...state, notify: 'Stubbing...' }
    default:
        return state;
    }
}
