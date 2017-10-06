import React from 'react';

var Template = props => (
        <div>
        <div>{props.template.name}</div>
        <div>{props.template.id}</div>
        </div>
);

var App = props => (
    <div>
        <select onChange={(e) => props.onStubSelect(e.target.selectedIndex)}>
        {props.stubReducer.templates.map(t => (
                <option key={t.id} value={t.id}>{t.name}</option>
        ))}
        </select>
        <Template template={props.stubReducer.current} />
    </div>
);

export default App;
