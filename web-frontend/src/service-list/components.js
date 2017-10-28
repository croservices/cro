import React from 'react';

var Endpoint = props => (
    <div>
      {(props.e[2] == 'http' || props.e[2] == 'https') &&
      <h5>Endpoint {props.e[0]}: <a href={props.e[2] + '://localhost:' + props.e[1]} target="_blank">{props.e[1]}</a> ({props.e[2]})</h5>
      }
      {(props.e[2] !== 'http' && props.e[2] !== 'https') &&
          <h5>Endpoint {props.e[0]}: {props.e[1]} ({props.e[2]})</h5>
      }
    </div>
);

var Service = props => (
    <div>
      <div className="serviceCreds">
        <h5>{props.service.name} <small>{props.service.id}</small></h5>
        {props.service.endpoints.map(v => (
            <div key={v[0]}>
              <Endpoint e={v} />
            </div>
        ))}
        <a href="#" onClick={() => props.onGotoLogs(props.service.id)} className="btn btn-sm btn-primary logBtn">Logs</a>
      </div>
      <div className="serviceManageBox">
        <h5>{props.service.status}</h5>
        {props.service.status !== 'Running' &&
            <button className="btn btn-sm btn-primary squareBtn" title="Start" onClick={() => props.onServiceStart(props.service.id)}><span className="glyphicon glyphicon-play"></span></button>
            }
            {props.service.status == 'Running' &&
                <button className="btn btn-sm  btn-primary squareBtn" title="Restart" onClick={() => props.onServiceRestart(props.service.id)}><span className="glyphicon glyphicon-repeat"></span></button>
                }
                {props.service.status == 'Running' &&
                    <button className="btn btn-sm btn-primary squareBtn" title="Stop" onClick={() => props.onServiceStop(props.service.id)}><span className="glyphicon glyphicon-stop"></span></button>
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
