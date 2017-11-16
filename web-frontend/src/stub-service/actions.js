import $ from 'jquery';

export const STUB_TEMPLATES             = 'STUB_TEMPLATES';
export const STUB_NEW_LINK              = 'STUB_NEW_LINK';
export const STUB_SET_PATH              = 'STUB_SET_PATH';
export const STUB_STUBBED               = 'STUB_STUBBED';
export const STUB_OPTIONS_ERROR_OCCURED = 'STUB_OPTIONS_ERROR_OCCURED';
export const STUB_STUB_ERROR_OCCURED    = 'STUB_STUB_ERROR_OCCURED';
// User actions
export const STUB_SELECT                = 'STUB_SELECT';
export const STUB_CHANGE_ID_TEXT        = 'STUB_CHANGE_ID_TEXT';
export const STUB_CHANGE_PATH_TEXT      = 'STUB_CHANGE_PATH_TEXT';
export const STUB_CHANGE_NAME_TEXT      = 'STUB_CHANGE_NAME_TEXT';
export const STUB_CHANGE_OPTION         = 'STUB_CHANGE_OPTION';
export const STUB_CHANGE_LINK           = 'STUB_CHANGE_LINK';
export const STUB_STUB_SENT             = 'STUB_STUB_SENT';
export const STUB_UNMOUNT               = 'STUB_UNMOUNT';

export function stubSelect(index) {
    return { type: STUB_SELECT, index };
}

export function stubChangeIdText(text) {
    return { type: STUB_CHANGE_ID_TEXT, text };
}

export function stubChangePathText(text) {
    return { type: STUB_CHANGE_PATH_TEXT, text };
}

export function stubChangeNameText(text) {
    return { type: STUB_CHANGE_NAME_TEXT, text };
}

export function stubChangeOption(id, value) {
    return { type: STUB_CHANGE_OPTION, id, value }
}

export function stubChangeLink(id, end, value) {
    return { type: STUB_CHANGE_LINK, id, end, value }
}

export function stubStub(id, name, path, type, options, services) {
    var name = name == '' ? id : name;
    var links = [];
    var servicesArray = Array.from(services);
    servicesArray.map((service) => {
        Array.from(service[1]).map((endpoint) => {
            if (endpoint.link)
                links.push({service: service[0], endpoint: endpoint.endpointId});
        });
    });
    return dispatch => {
        $.ajax({
            url: '/stub',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({ id, name, type, path, options: Array.from(options), links }),
            success: () => dispatch({ type: STUB_STUB_SENT })
        });
    };
}

export function stubUnmount() {
    return { type: STUB_UNMOUNT };
}
