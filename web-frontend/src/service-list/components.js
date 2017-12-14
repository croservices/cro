import React from 'react';
import { Link } from 'react-router';

var Endpoint = props => (
    <div>
      {(props.e[2] == 'http' || props.e[2] == 'https') &&
      <li>
       <div className="serviceEndPointName">{props.e[0]}</div>
       <div className="serviceEndPointInfo"><a href={props.e[2] + '://localhost:' + props.e[1]} target="_blank">{props.e[1]}</a> ({props.e[2]})</div>
      </li>
      }
      {(props.e[2] !== 'http' && props.e[2] !== 'https') &&
       <li>
        <div className="serviceEndPointName">{props.e[0]}:</div>
        <div className="serviceEndPointInfo">{props.e[1]} ({props.e[2]})</div>
       </li>
      }
    </div>
);

var Service = props => (
    <section>
      <div className="serviceCreds">
        <div>
          <div className="serviceTitle">{props.service.name}</div>
          <div className="serviceId">{props.service.id}</div>
        </div>

        <div className={"serviceStatus " + 'serviceStatus-' + props.service.status.toLowerCase()}>{props.service.status}</div>
      </div>
      <div className="serviceManageBox">
        <div className="serviceButtons">
        <a href="#" onClick={() => props.onGotoLogs(props.service.id)} className="btn btn-sm btn-primary logBtn">Logs</a>
        {props.service.status !== 'Running' &&
            <button className="btn btn-sm btn-primary squareBtn" title="Start" onClick={() => props.onServiceStart(props.service.id)}><span className="glyphicon glyphicon-play"></span></button>
            }
            {props.service.status == 'Running' &&
                <button className="btn btn-sm  btn-primary squareBtn" title="Restart" onClick={() => props.onServiceRestart(props.service.id)}><span className="glyphicon glyphicon-repeat"></span></button>
                }
                {props.service.status == 'Running' &&
                    <button className="btn btn-sm btn-primary squareBtn" title="Stop" onClick={() => props.onServiceStop(props.service.id)}><span className="glyphicon glyphicon-stop"></span></button>
                }
    {props.service.status == 'Running' &&
                        <button className={"btn btn-sm traceBtn squareBtn " + (props.service.trace ? "traceBtn-pressed" : "")} title="Toggle trace" onClick={(e) => props.onServiceTraceFlip(props.service.id, props.service.trace)}><span className="glyphicon glyphicon-eye-open"></span></button>
    }
    </div>

    <div className="serviceSubtitle">Endpoints</div>
        <div>
        <ul className="serviceEndPointList">
          <div className="linksURL"><li>
              <a onClick={() => {props.history.push('/links/' + props.service.id);}}>Links</a>
          </li></div>
        {props.service.endpoints.map(v => (
              <div className="serviceEndPoint" key={v[0]}>
                <Endpoint e={v} />
              </div>
        ))}
        </ul>
        </div>

      </div>
    </section>
);

var App = props => (
    <div>
      {Array.from(props.serviceListReducer.services).map(v => (
          <div className="service" key={v[0]}>
            <Service service={v[1]}
                     history={props.history}
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
