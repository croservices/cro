import * as ActionTypes from './actions';

const initialState = {
    services: new Map()
}

export default function serviceListReducer(state = initialState, action) {
    switch (action.type) {
    case ActionTypes.SERVICE_START_SENT:
        var updated_services = state.services;
        updated_services.get(action.id).status = 'Starting...';
        return { ...state, services: updated_services }
    case ActionTypes.SERVICE_STARTED:
        var service = { name: action.name, id: action.id, status: 'Running', trace: action.tracing };
        let new_services = state.services;
        new_services.set(service.id, service);
        return { ...state, services: new_services };
    case ActionTypes.SERVICE_RESTARTED:
        var updated_services = state.services;
        updated_services.get(action.id).status = 'Running';
        return { ...state, services: updated_services };
    case ActionTypes.SERVICE_RESTART_SENT:
        var updated_services = state.services;
        updated_services.get(action.id).status = 'Restarting...';
        return { ...state, services: updated_services };
    case ActionTypes.SERVICE_STOPPED:
        var updated_services = state.services;
        updated_services.get(action.id).status = 'Stopped';
        return { ...state, services: updated_services };
    case ActionTypes.SERVICE_STOPPED_SENT:
        var updated_services = state.services;
        updated_services.get(action.id).status = 'Stopping...';
        return { ...state, services: updated_services };
    case ActionTypes.SERVICE_FLIP:
        var updated_services = state.services;
        updated_services.get(action.id).trace = action.switch_state;
        return { ...state, services: updated_services };
    default:
        return state;
    }
}
