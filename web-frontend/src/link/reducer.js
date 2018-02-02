import * as ActionTypes from './actions';

const initialState = {
    links: new Map(),
    servicePool: new Map(),
    currentId: null,
    canCreateLink: false,
    // Code show state
    currentCode: "",
    codeShown: false,
    currentCodeService: null,
    currentCodeEP: null,
    // New link state
    newLinkService: null,
    newLinkEP: null,
    errorMsg: null
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
    case ActionTypes.LINK_GOTO_LINKS:
        var canCreateLink = state.canCreateLink;
        var newLinkService = state.newLinkService;
        var newLinkEP = state.newLinkEP;
        var servicePool = state.servicePool;
        if (newLinkService == null && servicePool.size > 0) {
            servicePool.forEach(function(v, k) {
                if (newLinkService == null && k != action.id) {
                    newLinkService = k;
                    newLinkEP = v[0];
                }
            });
        }
        const canCreateLink = findLink(links.get(action.id), newLinkService, newLinkEP) < 0;
        return { ...state, currentId: action.id, newLinkService, newLinkEP, canCreateLink, errorMsg: null };
    case ActionTypes.LINK_CREATE_LINK:
        var currLinks = links.get(state.currentId);
        currLinks.push({ service: action.service, endpoint: action.endpoint, code: 'Awaiting...' });
        links.set(state.currentId, currLinks);
        return { ...state, links, canCreateLink: false };
    case ActionTypes.LINK_INIT:
        var servicePool = state.servicePool;
        for (var i = 0; i < action.services.length; i++) {
            var service = action.services[i];
            servicePool.set(service.id, service.endpoints);
            if (service.links != undefined) {
                links.set(service.id, service.links);
            } else {
                links.set(service.id, []);
            }
        }
        return { ...state, links, servicePool };
    case ActionTypes.LINK_SHOW_LINK:
        var currentCode = state.currentCode;
        var codeShown;
        if (!(state.currentCodeEP === action.link.endpoint && state.currentCodeService === action.link.service)) {
            codeShown = true;
            var serviceLinks = links.get(state.currentId);
            for (var i=0; i < serviceLinks.length; i++) {
                if (serviceLinks[i].service == action.link.service && serviceLinks[i].endpoint == action.link.endpoint) {
                    currentCode = serviceLinks[i].code;
                }
            }
        } else {
            codeShown = !state.codeShown;
        }
        return { ...state, currentCode,
                 currentCodeEP: action.link.endpoint,
                 currentCodeService: action.link.service,
                 codeShown };
    case ActionTypes.LINK_REMOVE_LINK:
        var serviceLinks = links.get(state.currentId);
        var newLinks = [];
        for (var i=0; i < serviceLinks.length; i++) {
            if (!(serviceLinks[i].service  === action.service &&
                  serviceLinks[i].endpoint === action.endpoint)) {
                newLinks.push(serviceLinks[i]);
            }
        }
        var canCreateLink = findLink(newLinks, state.newLinkService, state.newLinkEP) < 0;
        links.set(state.currentId, newLinks);
        return { ...state, links, canCreateLink };
    case ActionTypes.LINK_ERROR:
        return { ...state, errorMsg: action.errorMsg };
    case ActionTypes.LINK_NEW_LINK_SERVICE_SELECT:
        var newLinkEP = state.servicePool.get(action.id)[0];
        var canCreateLink = findLink(links.get(state.currentId), action.id, newLinkEP) < 0;
        return { ...state, newLinkService: action.id, newLinkEP, canCreateLink, errorMsg: null };
    case ActionTypes.LINK_NEW_LINK_ENDPOINT_SELECT:
        var canCreateLink = findLink(links.get(state.currentId), action.currService, action.id) < 0;
        return { ...state, newLinkEP: action.id, canCreateLink, errorMsg: null };
    case ActionTypes.LINK_CODE:
        var serviceLinks = links.get(action.id);
        const linkID = findLink(serviceLinks, action.service, action.endpoint);
        if (linkID >= 0) {
            serviceLinks[linkID].code = action.code;
        }
        links.set(action.id, serviceLinks);
        return { ...state, links };
    default:
        return state;
    }
}
