import $ from 'jquery';
import ActionTypes from './actions';

const initialState = {
    services: new Map()
}

export function serviceListReducer(state = initialState, action) {
    switch (action.type) {
    case Action.Types.SERVICE_START:
        let updated_services = state.services;
        updated_services.get(action.id).status = 'Started';
        return { ...state, services: updated_services }
    }
    
}
