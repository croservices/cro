import * as ActionTypes from './actions';

const initialState = {
    links: new Map(),
    currentCode: "",
    codeShown: false,
    currentEP: null,
    newLinkService: null,
    newLinkEP: null,
    errorMsg: null,
    servicePool: new Map(),
    canCreateLink: true
};

function findLink(links, service, ep) {
    for (var i=0; i < links.length; i++) {
        if (links[i].service == service &&
            links[i].endpoint == ep) {
            return i;
        }
    }
    return -1;
}

export default function linkReducer(state = initialState, action) {
    var links = state.links;
    switch (action.type) {
    case ActionTypes.LINK_CREATE_LINK:
        var currLinks = links.get(action.id);
        currLinks.push({ service: action.service, endpoint: action.endpoint, code: 'Awaiting...' });
        links.set(action.id, currLinks);
        return { ...state, links, canCreateLink: false };
    case ActionTypes.LINK_ADD_LINK:
        if (action.links != undefined) {
            links.set(action.id, action.links);
        } else {
            links.set(action.id, []);
        }
        var newLinkService = state.newLinkService;
        var newLinkEP =  state.newLinkEP;
        var servicePool = state.servicePool;
        servicePool.set(action.id, action.endpoints);
        if (newLinkService == null) {
            newLinkService = action.id;
            newLinkEP = action.endpoints[0];
        }
        return { ...state, links, newLinkService, newLinkEP, servicePool };
    case ActionTypes.LINK_SHOW_LINK:
        var code = state.currentCode;
        var codeShown;
        if (state.currentEP != action.link.endpoint) {
            codeShown = true;
            var serviceLinks = links.get(action.id);
            for (var i=0; i < serviceLinks.length; i++) {
                if (serviceLinks[i].endpoint == action.link.endpoint) {
                    code = serviceLinks[i].code;
                }
            }
        } else {
            codeShown = !state.codeShown;
        }
        return { ...state, currentCode: code, currentEP: action.link.endpoint, codeShown };
    case ActionTypes.LINK_REMOVE_LINK:
        var serviceLinks = links.get(action.id);
        serviceLinks = serviceLinks.filter(item =>
                                           item.endpoint !== action.endpoint &&
                                           item.service !== action.service);
        links.set(action.id, serviceLinks);
        return { ...state, links };
    case ActionTypes.LINK_ERROR:
        return { ...state, errorMsg: action.errorMsg };
    case ActionTypes.LINK_NEW_LINK_SERVICE_SELECT:
        var newLinkEP = state.servicePool.get(action.id)[0];
        var canCreateLink = true;
        var serviceLinks = links.get(action.currId);
        if (findLink(serviceLinks, action.id, state.newLinkEP) >= 0) {
            canCreateLink = false;
        }
        return { ...state, newLinkService: action.id, newLinkEP, canCreateLink };
    case ActionTypes.LINK_NEW_LINK_ENDPOINT_SELECT:
        var canCreateLink = true;
        var serviceLinks = links.get(action.currId);
        if (findLink(serviceLinks, action.currService, action.id) >= 0) {
            canCreateLink = false;
        }
        return { ...state, newLinkEP: action.id, canCreateLink };
    case ActionTypes.LINK_CODE:
        var serviceLinks = links.get(action.id);
        if (findLink(serviceLinks, action.service, action.endpoint) >= 0) {
            serviceLinks[i].code = action.code;
        }
        links.set(action.id, serviceLinks);
        return { ...state, links };
    default:
        return state;
    }
}
