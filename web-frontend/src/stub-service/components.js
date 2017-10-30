import React from 'react';

var Template = props => (
    <div>
      <label className="control-label" htmlFor="nameTextInput">New service name</label>
      <input type="text" className="form-control" id="nameTextInput" pattern="^.+$" value={props.nameText} onChange={e => props.onChangeNameText(e.target.value)} />
      <label className="control-label" htmlFor="idTextInput">New service ID</label>
      <input type="text" className="form-control" id="idTextInput" pattern="^.+$" value={props.idText} onChange={e => props.onChangeIdText(e.target.value)} />
      <label className="control-label" htmlFor="pathTextInput">New service path</label>
      <input type="text" className="form-control" id="pathTextInput" pattern="^.+$" value={props.pathText} onChange={e => props.onChangePathText(e.target.value)} />
        <small>Service will be created in {props.fullPath}</small>
      {props.template !== null &&<div>
            <h3>{props.template.name} <small>{props.template.id}</small></h3>
                {props.template.options.map((opt, index) => (
                    <div className="checkbox" key={index}>
                      <label className="control-label">
                        <input type="checkbox" checked={opt[3]} onChange={(e) => props.onChangeOption(opt[0], e.target.checked)} />
                          {opt[1]}
                      </label>
                    </div>
                ))}
       <button className="btn btn-primary" id="stubButton" disabled={props.disable} onClick={(e) => props.onStubSent(props.idText, props.nameText, props.pathText, props.template.id, props.template.options.map(e => ( [e[0], e[3]] )))}>Stub</button>
       </div>}
     </div>
);

var App = props => (
    <div>
      <h3>Stub New Service</h3>
      {props.stubReducer.notify !== '' &&
       <div className="alert alert-success" role="alert">{props.stubReducer.notify}</div>
      }
      {props.stubReducer.optionErrors.length != 0 &&
       <div className="alert alert-danger" role="alert">{props.stubReducer.optionErrors}</div>
      }
      {props.stubReducer.stubErrors.length != 0 &&
       <div className="alert alert-danger" role="alert">{props.stubReducer.stubErrors}</div>
      }
      <label className="control-label" htmlFor="templateSelectInput">Service Template</label>
      <select id="templateSelectInput" defaultValue={props.stubReducer.current.id} className="form-control" onChange={(e) => props.onStubSelect(e.target.selectedIndex)}>
        {props.stubReducer.templates.map(t => (
            <option key={t.id} value={t.id}>{t.name}</option>
        ))}
    </select>
        <Template fullPath={props.stubReducer.fullPath}
            idText={props.stubReducer.idText}
            nameText={props.stubReducer.nameText}
            pathText={props.stubReducer.pathText}
            template={props.stubReducer.current}
            disable={props.stubReducer.disable}
            onChangeIdText={props.onChangeIdText}
            onChangePathText={props.onChangePathText}
            onChangeNameText={props.onChangeNameText}
            onChangeOption={props.onChangeOption}
            onStubSent={props.onStubSent} />
        </div>
);

export default App;
