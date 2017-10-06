import $ from 'jquery';

export const SERVICE_STARTED = 'SERVICE_STARTED';
export const SERVICE_UNABLE_TO_START = 'SERVICE_UNABLE_TO_START';
export const SERVICE_RESTARTED = 'SERVICE_RESTARTED';
export const SERVICE_STOPPED = 'SERVICE_STOPPED';
export const SERVICE_LOG = 'SERVICE_LOG';
export const SERVICE_TRACE = 'SERVICE_TRACE';
// User actions
export const SERVICE_START = 'SERVICE_START';
export const SERVICE_RESTART = 'SERVICE_RESTART';
export const SERVICE_STOP = 'SERVICE_STOP';
export const SERVICE_TRACE_FLIP = 'SERVICE_TRACE_FLIP';

function sendAction(id, action, type) {
    return dispatch => {
        $.ajax({
            url: '/service',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({ id, action }),
            success: () => dispatch({ id, type })
        });
    }
}

export function serviceStart(id) {
    return sendAction(id, 'start', SERVICE_STARTED + '_skip');
}

export function serviceRestart(id) {
    return sendAction(id, 'restart', SERVICE_RESTARTED + '_skip');
}

export function serviceStop(id) {
    return sendAction(id, 'stop', SERVICE_STOPPED);
}

export function serviceTrace(id) {
    return (dispatch, getState) => {
        // Get current state from a Map with switches states
        var state = getState().services.get(id).status;
        $.ajax({
            url: '/service',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({ id, action: 'flip', state }),
            success: () => dispatch({
                type: 'SERVICE_FLIP', switch_state: state === 'ON' ? 'OFF' : 'ON'
            })
        })
    }
}
