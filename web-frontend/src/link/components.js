import React from 'react';

var App = props => (
    <div>
      <h3>Service links</h3>
      {props.linkReducer.errorMsg != null &&
        <div className="alert alert-danger" role="alert">
          <pre><code>
            {props.linkReducer.errorMsg}
          </code></pre>
        </div>}
      {props.linkReducer.links.get(props.service_id) != undefined &&
       <div>
           <ul>
             {Array.from(props.linkReducer.links.get(props.service_id)).map(l => (
               <div className="linkSection" key={l.service + l.endpoint}>
                 <li>
                   <div className="linkName">{l.service}:{l.endpoint}</div>
                   <div className="linkControlPanel">
                     <button className="btn btn-primary linkCodeButton" onClick={(e) => props.onShowCode(props.service_id, l)}>Show code</button>
                     <button className="btn btn-primary linkRemoveButton" onClick={(e) => props.onRemoveLink(props.service_id, l.service, l.endpoint)}>Remove link</button>
                   </div>
                 </li>
               </div>
             ))}
           </ul>
           <div id="linkCodeSection">
             {props.linkReducer.codeShown &&
             <pre><code>
              {props.linkReducer.currentCode}
              </code></pre>}
           </div>
       </div>
      }
      {(props.linkReducer.links.get(props.service_id) == undefined
        || props.linkReducer.links.get(props.service_id).length == 0) &&
       <div>No links yet.</div>}
      <div id="addLinkContainer">
        <select id="linkServiceInput" defaultValue={props.linkReducer.newLinkService || ''} className="form-control" onChange={(e) => props.onNewLinkServiceSelect(e.target.options[e.target.selectedIndex].value, props.service_id)}>
        {props.linkReducer.servicePool.size != 0 && Array.from(props.linkReducer.servicePool).filter(item => item[0] !== props.service_id).map((sid) => (
            <option key={sid[0]} value={sid[0]}>{sid[0]}</option>
        ))}
        </select>
        <select id="linkEndpointInput" defaultValue={props.linkReducer.newLinkEP || ''} className="form-control" onChange={(e) => props.onNewLinkEndpointSelect(e.target.options[e.target.selectedIndex].value, props.service_id)}>
        {props.linkReducer.servicePool.size != 0 && props.linkReducer.servicePool.get(props.linkReducer.newLinkService).map(ep => (
            <option key={ep} value={ep}>{ep}</option>
          ))}
        </select>
        <button className="btn btn-primary" id="newLinkButton" disabled={!props.linkReducer.canCreateLink} onClick={(e) => props.onCreateLink(props.service_id, props.linkReducer.newLinkService, props.linkReducer.newLinkEP)}>Add Link</button>
      </div>
    </div>
);

export default App;
