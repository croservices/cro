export const STUB_TEMPLATES = 'STUB_TEMPLATES';
// User actions
export const STUB_SELECT = 'STUB_SELECT';
export const STUB_STUB = 'STUB_STUB'

export function stubSelect(index) {
    return { type: STUB_SELECT, index };
}

export function stubSelect(id) {
    return { type: STUB_STUB, id };
}
