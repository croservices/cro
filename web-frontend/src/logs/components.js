import React from 'react';

var App = props => (
    <div>
      <select className="form-control" value={props.logsReducer.current} onChange={e => props.onSelectChannel(e.target.options[e.target.selectedIndex].value)}>
        {Array.from(props.logsReducer.channels).map(c => (
            <option key={c[0]}>{c[0]}</option>
        ))}
    </select>
        {props.logsReducer.channels.get(props.logsReducer.current) &&
         <div className="log">{props.logsReducer.channels.get(props.logsReducer.current)}</div>
        }
    </div>
);

export default App;
