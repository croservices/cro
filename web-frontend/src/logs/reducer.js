import * as ActionTypes from './actions';

const initialState = {
    channels: new Map([['All Services', 'Logging is started.\n']]),
    current: 'All Services'
};

export default function logsReducer(state = initialState, action) {
    switch (action.type) {
    case ActionTypes.LOGS_NEW_CHANNEL:
        var channels = state.channels;
        var msg = 'Service ' + action.id + ' is started.\n'
        var log = channels.get(action.id);
        var all_log = channels.get('All Services');
        all_log = all_log + msg;
        if (log != undefined) {
            channels.set(action.id, log + msg);
        } else {
            channels.set(action.id, msg);
        }
        channels.set('All Services', all_log);
        return {...state, channels};
    case ActionTypes.LOGS_UPDATE_CHANNEL:
        var channels = state.channels;
        var log = channels.get(action.id);
        var all_log = channels.get('All Services');
        all_log = all_log + action.id + ': ' + action.payload + "\n";
        if (log != undefined) {
            log = log + action.payload + "\n";
        } else {
            log = action.payload + "\n";
        }
        channels.set(action.id, log);
        channels.set('All Services', all_log);
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
