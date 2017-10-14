import React from 'react';

var Service = props => (
    <div>
      <div className="serviceCreds">
        <h5>{props.service.name} <small>{props.service.id}</small></h5>
        <button className="logLink btn btn-primary" onClick={() => props.onGotoLogs(props.service.id)}>Logs</button>
      </div>
      <div className="serviceManageBox">
        <h5>{props.service.status}</h5>
        {props.service.status !== 'Running' &&
            <button className="btn-primary" onClick={() => props.onServiceStart(props.service.id)}><span className="glyphicon glyphicon-play"></span></button>
            }
            {props.service.status == 'Running' &&
                <button className="btn-primary" onClick={() => props.onServiceRestart(props.service.id)}><span className="glyphicon glyphicon-repeat"></span></button>
                }
                {props.service.status == 'Running' &&
                    <button className="btn btn-primary" onClick={() => props.onServiceStop(props.service.id)}><span className="glyphicon glyphicon-stop"></span></button>
                    }
                    <div className="checkbox">
                      <label>
                        <input onChange={(e) => props.onServiceTraceFlip(props.service.id, e.target.checked)} name="traceSwitch" type="checkbox" /> Trace
                      </label>
                    </div>
      </div>
    </div>
);

var App = props => (
    <div>
      {Array.from(props.serviceListReducer.services).map(v => (
          <div className="service" key={v[0]}>
            <Service service={v[1]}
                     onServiceStart={props.onServiceStart}
                     onServiceStop={props.onServiceStop}
                     onServiceRestart={props.onServiceRestart}
                     onServiceTraceFlip={props.onServiceTraceFlip}
                     onGotoLogs={props.onGotoLogs} />
          </div>
      ))}
    </div>
);
export default App;
