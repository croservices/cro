import $ from 'jquery';
import ActionTypes from './actions';

const initialState = {
    services: new Map()
}

export function serviceListReducer(state = initialState, action) {
    switch (action.type) {
    case Action.Types.SERVICE_START:
        state.services.get(action.id).status = 'Started';
        return { ...state, services: services }
    }
    
}
