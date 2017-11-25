import * as ActionTypes from './actions';

const initialState = {
    graph: null
};

export default function overviewReducer(state = initialState, action) {
    switch (action.type) {
    case ActionTypes.OVERVIEW_GRAPH:
        return { ...state, graph: action.graph }
    case ActionTypes.OVERVIEW_ADD_NODE:
        const graph = state.graph;
        graph.nodes.push(action.node);
        for (var i = 0; i < action.links.length; i++) {
            graph.links.push(action.links[i]);
        }
        return { ...state, graph }
    case ActionTypes.OVERVIEW_CREATE_NEW:
        return state;
    default:
        return state;
    }
}
