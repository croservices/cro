import React from 'react';

var App = props => (
    <div>
      {props.graph != null &&
          <div id="overview"></div>
      }
      {props.graph == null &&
          <div>
              <h3>No known services...</h3>
              <button className="btn btn-primary">Create one now</button>
          </div>
      }
    </div>
);

export default App;
