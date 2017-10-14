import * as ActionTypes from './actions';

const initialState = {
    channels: new Map(),
    current: null
};

export default function logsReducer(state = initialState, action) {
    switch (action.type) {
    case ActionTypes.LOGS_NEW_CHANNEL:
        var channels = state.channels;
        if (state.current != null) {
            state.current = action.id;
        }
        if (channels.get(action.id) == null) {
            channels.set(action.id, '');
        }
        return {...state, channels};
    case ActionTypes.LOGS_UPDATE_CHANNEL:
        var channels = state.channels;
        var log = channels.get(action.id);
        log = log + action.payload + "<br>";
        channels.set(action.id, log);
        return {...state, channels };
    case ActionTypes.LOGS_SELECT_CHANNEL:
        return {...state, current: action.id};
    case ActionTypes.SERVICE_GOTO_LOGS:
        state.current = action.id;
        return state;
    default:
        return state;
    }
}
