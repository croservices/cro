import { browserHistory } from 'react-router';

export const OVERVIEW_GRAPH = 'OVERVIEW_GRAPH';
export const OVERVIEW_CREATE_NEW = 'OVERVIEW_CREATE_NEW';

export function createNew() {
    browserHistory.push("/stub");
    return { id, type: OVERVIEW_CREATE_NEW }
}
