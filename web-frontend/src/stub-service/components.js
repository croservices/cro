import React from 'react';

var Template = props => (
    <div>
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
       <label className="control-label" htmlFor="idTextInput">New service id</label>
       <input type="text" className="form-control" id="idTextInput" pattern="^.+$" value={props.idText} onChange={e => props.onChangeIdText(e.target.value)} />
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
      <select className="form-control" onChange={(e) => props.onStubSelect(e.target.selectedIndex)}>
        {props.stubReducer.templates.map(t => (
            <option key={t.id} value={t.id}>{t.name}</option>
        ))}
    </select>
        <Template idText={props.stubReducer.idText}
            template={props.stubReducer.current}
            notify={props.stubReducer.notify}
            option_errors={props.stubReducer.option_errors}
            stub_errors={props.stubReducer.stub_errors}
            onChangeIdText={props.onChangeIdText}
            onChangeOption={props.onChangeOption}
            onStubSent={props.onStubSent} />
        </div>
);

export default App;
