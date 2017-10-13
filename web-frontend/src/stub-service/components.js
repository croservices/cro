import React from 'react';

var Template = props => (
    <div>
      {props.template !== null &&<div>
            <h3>{props.template.name} <small>{props.template.id}</small></h3>
                {props.template.options.map((opt, index) => (
                    <div className="checkbox" key={index}>
                      <label className="control-label">
                        <input type="checkbox" onChange={(e) => props.onChangeOption(opt[0], e.target.checked)} />
                          {opt[1]}
                      </label>
                    </div>
                ))}
       <label className="control-label" htmlFor="idTextInput">New service id</label>
       <input type="text" className="from-control" id="idTextInput" pattern="^[A-Za-z0-9_]+$" value={props.id} onChange={e => props.onChangeIdText(e.target.value)} />
       <input className="btn btn-primary" type="button" value="Stub" onClick={(e) => props.onStub(props.idText, props.template.id, props.template.options.map(e => ( [e[0], e[3]] )))} />
       </div>}
    {props.notify}
    {props.option_errors}
    </div>
);

var App = props => (
    <div>
      <select className="from-control" onChange={(e) => props.onStubSelect(e.target.selectedIndex)}>
        {props.stubReducer.templates.map(t => (
            <option key={t.id} value={t.id}>{t.name}</option>
        ))}
    </select>
        <Template idText={props.stubReducer.idText}
            template={props.stubReducer.current}
            notify={props.stubReducer.notify}
            onChangeIdText={props.onChangeIdText}
            onChangeOption={props.onChangeOption}
            onStub={props.onStub} />
        </div>
);

export default App;
