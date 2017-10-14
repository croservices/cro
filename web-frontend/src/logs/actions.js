import { browserHistory } from 'react-router';

export const LOGS_NEW_CHANNEL    = 'LOGS_NEW_CHANNEL';
export const LOGS_UPDATE_CHANNEL = 'LOGS_UPDATE_CHANNEL';
// User actions
export const LOGS_SELECT_CHANNEL = 'LOGS_SELECT_CHANNEL';
export const SERVICE_GOTO_LOGS   = 'SERVICE_GOTO_LOGS';

export function logsSelectChannel(id) {
    return { id, type: LOGS_SELECT_CHANNEL }
}

export function serviceGotoLogs(id) {
    browserHistory.push("/logs");
    return { id, type: SERVICE_GOTO_LOGS }
}
