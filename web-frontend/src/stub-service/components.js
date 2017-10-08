import React from 'react';

var Template = props => (
    <div>
      {props.template !== null &&<div>
            <div>{props.template.name}</div>
                <div>{props.template.id}</div>
                    {props.template.options.map((opt, index) => (
                        <div key={index}>
                          {opt[1]}
                          <input onChange={(e) => props.onChangeOption(opt[0], e.target.checked)} type="checkbox"/>
                        </div>
                    ))}
       Service id:
       <input type="text" pattern="^[A-Za-z0-9_]{1,32}$" value={props.id} onChange={e => props.onChangeIdText(e.target.value)} />
       <input type="button" value="Stub" onClick={(e) => props.onStub(props.idText, props.template.id, props.options)} />
       </div>}
    </div>
);

var App = props => (
    <div>
      <select onChange={(e) => props.onStubSelect(e.target.selectedIndex)}>
        {props.stubReducer.templates.map(t => (
            <option key={t.id} value={t.id}>{t.name}</option>
        ))}
    </select>
        <Template idText={props.stubReducer.idText}
            template={props.stubReducer.current}
            options={props.stubReducer.options}
            onChangeIdText={props.onChangeIdText}
            onChangeOption={props.onChangeOption}
            onStub={props.onStub} />
        </div>
);

export default App;
