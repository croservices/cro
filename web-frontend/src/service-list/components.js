import React from 'react';

var Service = props => (
    <div> <div className="serviceCreds">
        <div className="serviceName">{props.service.name}</div>
        <div className="serviceId">{props.service.id}</div>
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
                    <input onChange={(e) => props.onServiceTraceFlip(props.service.id, e.target.checked)} className="serviceControl" id="checkBox" type="checkbox" />
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
