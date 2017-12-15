import * as ActionTypes from './actions';

const initialState = {
    graph: null
};

export default function overviewReducer(state = initialState, action) {
    switch (action.type) {
    case ActionTypes.OVERVIEW_GRAPH:
        return { ...state, graph: action.graph };
    case ActionTypes.OVERVIEW_ADD_NODE:
        var graph = state.graph;
        graph.nodes.push(action.node);
        for (var i = 0; i < action.links.length; i++) {
            graph.links.push(action.links[i]);
        }
        return { ...state, graph };
    case ActionTypes.OVERVIEW_ADD_LINK:
        var graph = state.graph;
        var link = { source: action.source,
                     target: action.target,
                     type: action.color };
        graph.links.push(link);
        return { ...state, graph };
    case ActionTypes.OVERVIEW_REMOVE_LINK:
        var graph = state.graph;
        var links = graph.links.filter(item =>
                                       !(action.source === item.source.id &&
                                         action.target === item.target.id));
        graph.links = links;
        return { ...state, graph };
    default:
        return state;
    }
}
