import $ from 'jquery';

export const SERVICE_STARTED         = 'SERVICE_STARTED';
export const SERVICE_UNABLE_TO_START = 'SERVICE_UNABLE_TO_START';
export const SERVICE_RESTARTED       = 'SERVICE_RESTARTED';
export const SERVICE_STOPPED         = 'SERVICE_STOPPED';
// User actions
export const SERVICE_START_SENT      = 'SERVICE_START_SENT';
export const SERVICE_RESTART_SENT    = 'SERVICE_RESTART_SENT';
export const SERVICE_STOP_SENT       = 'SERVICE_STOP_SENT';
export const SERVICE_TRACE_FLIP      = 'SERVICE_TRACE_FLIP';

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
    return sendAction(id, 'start', SERVICE_START_SENT);
}

export function serviceRestart(id) {
    return sendAction(id, 'restart', SERVICE_RESTART_SENT);
}

export function serviceStop(id) {
    return sendAction(id, 'stop', SERVICE_STOP_SENT);
}

export function serviceTraceFlip(id, checked) {
    return dispatch => {
        $.ajax({
            url: '/service',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({ id, action: (checked ? 'trace-off' : 'trace-on') }),
            success: () => dispatch({
                id, type: 'SERVICE_TRACE_FLIP', trace: (!checked)
            })
        })
    }
}
