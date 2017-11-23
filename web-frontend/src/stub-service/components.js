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
        {Array.from(props.links).length !== 0 &&
            <div>
              <label className="control-label">Services links</label>
              {Array.from(props.links).map((link, index) => (
                <div key={index}>
                  {link[1].map((endpoint, index) => (
                      <div className="checkbox" key={index}>
                        <label>
                          <input type="checkbox" onChange={(e) => props.onChangeLink(link[0], endpoint.endpointId, e.target.checked)} />
                          {link[0]} - {endpoint.endpointId}
                        </label>
                      </div>
                  ))}
                </div>
              ))}
         </div>
        }
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
       <button className="btn btn-primary" id="stubButton" disabled={props.disable} onClick={(e) =>
                                                                                             props.onStubSent(
                                                                                                 props.idText,
                                                                                                 props.nameText,
                                                                                                 props.pathText,
                                                                                                 props.template.id,
                                                                                                 props.template.options.map(e => ( [e[0], e[3]] )),
                                                                                                 props.links)}>Stub</button>
       </div>}
     </div>
);

class App extends React.Component {
    render() {
        return (
          <div>
            <h3>Stub New Service</h3>
            {this.props.stubReducer.notify !== '' && this.props.stubReducer.optionErrors.length == 0 && this.props.stubReducer.optionErrors.length == 0 &&
              <div className="alert alert-success" role="alert">{this.props.stubReducer.notify}</div>
            }
            {this.props.stubReducer.optionErrors.length != 0 &&
              <div className="alert alert-danger" role="alert">{this.props.stubReducer.notify} {this.props.stubReducer.optionErrors}</div>
            }
            {this.props.stubReducer.stubErrors.length != 0 &&
              <div className="alert alert-danger" role="alert">{this.props.stubReducer.notify} {this.props.stubReducer.stubErrors}</div>
            }
            <label className="control-label" htmlFor="templateSelectInput">Service Template</label>
            <select id="templateSelectInput" defaultValue={this.props.stubReducer.current && this.props.stubReducer.current.id || ''} className="form-control" onChange={(e) => this.props.onStubSelect(e.target.selectedIndex)}>
              {this.props.stubReducer.templates.map(t => (
                <option key={t.id} value={t.id}>{t.name}</option>
              ))}
            </select>
            {this.props.stubReducer.current &&
                <Template fullPath={this.props.stubReducer.fullPath}
                          idText={this.props.stubReducer.idText}
                          nameText={this.props.stubReducer.nameText}
                          pathText={this.props.stubReducer.pathText}
                          template={this.props.stubReducer.current}
                          links={this.props.stubReducer.links}
                          disable={this.props.stubReducer.disable}
                          onChangeIdText={this.props.onChangeIdText}
                          onChangePathText={this.props.onChangePathText}
                          onChangeNameText={this.props.onChangeNameText}
                          onChangeOption={this.props.onChangeOption}
                          onChangeLink={this.props.onChangeLink}
                          onStubSent={this.props.onStubSent} />}
          </div>
        );
    }

    componentWillUnmount() {
        this.props.stubUnmount();
    }
}

export default App;
