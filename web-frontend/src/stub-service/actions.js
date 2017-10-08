import $ from 'jquery';

export const STUB_TEMPLATES = 'STUB_TEMPLATES';
// User actions
export const STUB_SELECT = 'STUB_SELECT';
export const STUB_CHANGE_ID_TEXT = 'STUB_CHANGE_ID_TEXT';
export const STUB_CHANGE_OPTION = 'STUB_CHANGE_OPTION';
export const STUB_STUB = 'STUB_STUB';

export function stubSelect(index) {
    return { type: STUB_SELECT, index };
}

export function stubChangeIdText(text) {
    return { type: STUB_CHANGE_ID_TEXT, text };
}

export function stubChangeOption(id, value) {
    return { type: STUB_CHANGE_OPTION, id, value }
}

export function stubStub(id, type, options) {
    return dispatch => {
        $.ajax({
            url: '/stub',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({ id, type, options: Array.from(options) }),
            success: () => dispatch({ type: STUB_STUB })
        });
    };
}
