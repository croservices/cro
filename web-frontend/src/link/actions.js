import { browserHistory } from 'react-router';
import $ from 'jquery';

export const LINK_INIT                     = 'LINK_INIT';
export const LINK_ERROR                    = 'LINK_ERROR';
export const LINK_CODE                     = 'LINK_CODE';
// User actions.
export const LINK_SHOW_LINK                = 'LINK_SHOW_LINK';
export const LINK_CREATE_LINK              = 'LINK_CREATE_LINK';
export const LINK_REMOVE_LINK              = 'LINK_REMOVE_LINK';
export const LINK_NEW_LINK_SERVICE_SELECT  = 'LINK_NEW_LINK_SERVICE_SELECT';
export const LINK_NEW_LINK_ENDPOINT_SELECT = 'LINK_NEW_LINK_ENDPOINT_SELECT';
export const LINK_GOTO_LINKS               = 'LINK_GOTO_LINKS';

export function linkShowCode(link) {
    return { link, type: LINK_SHOW_LINK };
}

function postAction(request) {
    return dispatch => {
        $.ajax({
            url: '/link',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify(request),
            success: () => dispatch(request)
        });
    };
}

export function linkCreateLink(id, service, endpoint) {
    return postAction({ id, service, endpoint, type: LINK_CREATE_LINK });
}

export function linkRemoveLink(id, service, endpoint) {
    return postAction({ id, service, endpoint, type: LINK_REMOVE_LINK });
}

export function linkNewLinkServiceSelect(id, currEndpoint) {
    return { id, type : LINK_NEW_LINK_SERVICE_SELECT };
}

export function linkNewLinkEndpointSelect(id, currId, currService) {
    return { id, currService, type : LINK_NEW_LINK_ENDPOINT_SELECT };
}

export function linkGotoLinks(id) {
    browserHistory.push('/links/' + id);
    return { id, type : LINK_GOTO_LINKS };
}
