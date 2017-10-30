import * as ActionTypes from './actions';

const initialState = {
    services: new Map()
}

export default function serviceListReducer(state = initialState, action) {
    let services = state.services;
    let service = services.get(action.id);
    switch (action.type) {
    case ActionTypes.SERVICE_START_SENT:
        service.status = 'Starting';
        services.set(action.id, service);
        return { ...state, services }
    case ActionTypes.SERVICE_STARTED:
        service = { name: action.name, id: action.id, status: 'Running', trace: action.tracing, endpoints: action.endpoints };
        services.set(service.id, service);
        return { ...state, services };
    case ActionTypes.SERVICE_RESTARTED:
        service.status = 'Running';
        services.set(action.id, service);
        return { ...state, services: updated_services };
    case ActionTypes.SERVICE_RESTART_SENT:
        service.status = 'Restarting';
        services.set(action.id, service);
        return { ...state, services };
    case ActionTypes.SERVICE_STOPPED:
        service.status = 'Stopped';
        services.set(action.id, service);
        return { ...state, services };
    case ActionTypes.SERVICE_STOPPED_SENT:
        service.status = 'Stopping';
        services.set(action.id, service);
        return { ...state, services };
    case ActionTypes.SERVICE_TRACE_FLIP:
        service.trace = action.trace;
        services.set(action.id, service);
        return { ...state, services };
    default:
        return state;
    }
}
