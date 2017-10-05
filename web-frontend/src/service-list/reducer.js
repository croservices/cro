import * as ActionTypes from './actions';

const initialState = {
    services: new Map()
}

export default function serviceListReducer(state = initialState, action) {
    switch (action.type) {
    case ActionTypes.SERVICE_START:
        let updated_services = state.services;
        updated_services.get(action.id).status = 'Started';
        return { ...state, services: updated_services }
    case ActionTypes.SERVICE_STARTED:
        let service = { name: action.name };
        let new_services = state.services;
        new_services.set(service.name, service);
        return { ...state, services: new_services };
    default:
        return state;
    }
}
