import React from 'react';

var Template = props => (
    <div>
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
       <input className="btn btn-primary" type="button" value="Stub" onClick={(e) => props.onStubSent(props.idText, props.template.id, props.template.options.map(e => ( [e[0], e[3]] )))} />
       </div>}
    <label>{props.notify}</label>
    {props.option_errors.length != 0 &&
     <div>Incorrect options:
     {props.option_errors.map((e, index) => (
         <div className="option-error" key={index}>
           <label>{e}</label>
         </div>
     ))}
     </div>
    }
    {props.stub_errors.length != 0 &&
     <div>Stubbing went wrong:
     {props.stub_errors.map((e, index) => (
         <div className="stub-error" key={index}>
           <b>{e}</b>
         </div>
     ))}
     </div>
    }
    </div>
);

var App = props => (
    <div>
      <h3>Stub New Service</h3>
      <label className="control-label" htmlFor="templateSelectInput">Service Template</label>
      <select id="templateSelectInput" defaultValue={props.stubReducer.current.id} className="form-control" onChange={(e) => props.onStubSelect(e.target.selectedIndex)}>
        {props.stubReducer.templates.map(t => (
            <option key={t.id} value={t.id}>{t.name}</option>
        ))}
    </select>
        <Template fullPath={props.stubReducer.fullPath}
            idText={props.stubReducer.idText}
            pathText={props.stubReducer.pathText}
            template={props.stubReducer.current}
            notify={props.stubReducer.notify}
            option_errors={props.stubReducer.option_errors}
            stub_errors={props.stubReducer.stub_errors}
            onChangeIdText={props.onChangeIdText}
            onChangePathText={props.onChangePathText}
            onChangeOption={props.onChangeOption}
            onStubSent={props.onStubSent} />
        </div>
);

export default App;
