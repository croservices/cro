import path from 'path';
import * as ActionTypes from './actions';

const initialState = {
    templates: [],
    current: null,
    idText: '',
    pathText: '',
    nameText: '',
    notify: '',
    optionErrors: [],
    stubErrors: [],
    cwd: '',
    fullPath: '',
    disable: true
};

export default function stubReducer(state = initialState, action) {
    switch (action.type) {
    case ActionTypes.STUB_SET_PATH:
        var fullPath = path.join(state.cwd, action.path)
        return { ...state, fullPath, cwd: action.path }
    case ActionTypes.STUB_TEMPLATES:
        var templates = action.templates;
        templates.sort(function(a, b) {
            return a.id.localeCompare(b.id)
        });
        return { ...state, templates,
                 current: action.templates[0] }
    case ActionTypes.STUB_STUBBED:
        return { ...state, stubErrors: '', optionErrors: '',
                 idText: '', pathText: '', nameText: '',
                 notify: 'Successfully stubbed!', disabled: true }
    case ActionTypes.STUB_OPTIONS_ERROR_OCCURED:
        return { ...state, notify: 'Options error occured:', optionErrors: action.errors }
    case ActionTypes.STUB_STUB_ERROR_OCCURED:
        return { ...state, notify: 'Error occured during stubbing:', stubErrors: action.errors }

    case ActionTypes.STUB_SELECT:
        return { ...state, current: state.templates[action.index], notify: '' }
    case ActionTypes.STUB_CHANGE_ID_TEXT:
        var disable = action.text === '';
        if (state.idText === state.pathText) {
            var fullPath = path.join(state.cwd, action.text)
            return { ...state, idText: action.text, pathText: action.text, fullPath, disable }
        } else {
            return { ...state, idText: action.text, disable }
        }
    case ActionTypes.STUB_CHANGE_PATH_TEXT:
        var fullPath = path.join(state.cwd, action.text)
        return { ...state, pathText: action.text, fullPath }
    case ActionTypes.STUB_CHANGE_NAME_TEXT:
        return { ...state, nameText: action.text }
    case ActionTypes.STUB_CHANGE_OPTION:
        var opts = state.current.options;
        for (var i = 0; i < opts.length; i++) {
            if (opts[i][0] == action.id) {
                opts[i][3] = action.value;
            }
        }
        state.current.options = opts;
        return { ...state, notify: '', optionErrors: '', stubErrors: '' }
    case ActionTypes.STUB_STUB_SENT:
        return { ...state, notify: 'Stubbing...' }
    default:
        return state;
    }
}
