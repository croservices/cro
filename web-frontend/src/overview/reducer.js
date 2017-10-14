import * as ActionTypes from './actions';

const initialState = {
    graph: null
};

export default function overviewReducer(state = initialState, action) {
    console.log(action.type);
    switch (action.type) {
    case ActionTypes.OVERVIEW_GRAPH:
        console.log(action.graph);
        return { graph: action.graph }
    default:
        return state;
    }
}
