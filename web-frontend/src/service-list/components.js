import React from 'react';

var Service = props => (
    <div>
      <div className="serviceCreds">
        <h5>{props.service.name} <small>{props.service.id}</small></h5>
      </div>
      <div className="serviceManageBox">
        <div className="serviceStatus">{props.service.status}</div>
        {props.service.status !== 'Running' &&
            <button className="btn" onClick={() => props.onServiceStart(props.service.id)} className="serviceControl" type="button">▶</button>
            }
            {props.service.status == 'Running' &&
                <button className="btn" onClick={() => props.onServiceRestart(props.service.id)} className="serviceControl" type="button">🔄</button>
                }
                {props.service.status == 'Running' &&
                    <button className="btn" onClick={() => props.onServiceStop(props.service.id)} className="serviceControl" type="button">🛑</button>
                    }
                    <input className="form-check-input" onChange={(e) => props.onServiceTraceFlip(props.service.id, e.target.checked)} name="traceSwitch" type="checkbox" />
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
                     onServiceTraceFlip={props.onServiceTraceFlip} />
          </div>
      ))}
    </div>
);
export default App;
