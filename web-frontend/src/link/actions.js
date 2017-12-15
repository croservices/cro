import $ from 'jquery';

export const LINK_ADD_LINK                 = 'LINK_ADD_LINK';
export const LINK_ERROR                    = 'LINK_ERROR';
export const LINK_CODE                     = 'LINK_CODE';
// User actions.
export const LINK_SHOW_LINK                = 'LINK_SHOW_LINK';
export const LINK_CREATE_LINK              = 'LINK_CREATE_LINK';
export const LINK_REMOVE_LINK              = 'LINK_REMOVE_LINK';
export const LINK_NEW_LINK_SERVICE_SELECT  = 'LINK_NEW_LINK_SERVICE_SELECT';
export const LINK_NEW_LINK_ENDPOINT_SELECT = 'LINK_NEW_LINK_ENDPOINT_SELECT';

export function linkShowCode(id, link) {
    return { id, link, type: LINK_SHOW_LINK };
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

export function linkNewLinkServiceSelect(id, currId, currEndpoint) {
    return { id, currId, type : LINK_NEW_LINK_SERVICE_SELECT };
}

export function linkNewLinkEndpointSelect(id, currId, currService) {
    return { id, currId, currService, type : LINK_NEW_LINK_ENDPOINT_SELECT };
}
