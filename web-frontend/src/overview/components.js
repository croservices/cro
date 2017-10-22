import React from 'react';
import * as d3 from 'd3';
import {withFauxDOM} from 'react-faux-dom';

class GraphNetwork extends React.Component {
    constructor (props) {
        super(props);
        // FIXME: for some reason, `componentDidChange`'s second argument is always null,
        // so we cannot compare two states properly, hence the flag.
        this.done = false;
        this.renderD3 = this.renderD3.bind(this);
    }

    componentDidMount () {
        if (this.props.overviewReducer.graph != null) {
            this.done = true;
            this.renderD3();
        }
    }

    componentDidUpdate (oldState, newState) {
        if (!this.done && this.props.overviewReducer.graph !== null) {
            this.done = true;
            this.renderD3();
        }
    }

    renderD3() {
        var data = this.props.data;
        const faux = this.props.connectFauxDOM('div', 'chart');

        var width = 300,
            height = 300;

        var svg = d3.select(faux)
            .append('svg')
            .attr("width", width)
            .attr("height", height);

        svg = svg.call(d3.zoom().on("zoom", zoomed)).append("g");

        var simulation = d3.forceSimulation()
            .force("link", d3.forceLink().id(function(d) { return d.id; }))
            .force("charge", d3.forceManyBody())
            .force("center", d3.forceCenter(width / 2, height / 2));

        function createGraph (graph) {
            var color = d3.scaleOrdinal(d3.schemeCategory10);

            var link = svg.append("g")
                .attr("class", "links")
                .selectAll("line")
                .data(graph.links)
                .enter().append("line")
                .attr("stroke", function(d) { return color(d.type); })
                .attr("marker-end", "url(#marker_arrow)");

            var node = svg.append("g")
                .attr("class", "nodes")
                .selectAll("circle")
                .data(graph.nodes)
                .enter().append("circle")
                .attr("r", 10)
                .attr("fill", function(d) { if (d.root == "true") return color(d.root); return color(d.type); })
                .call(d3.drag()
                      .on("start", dragStarted)
                      .on("drag", dragged)
                      .on("end", dragEnded));

            var text = svg.append("g").attr("class", "labels").selectAll("g")
                .data(graph.nodes)
                .enter().append("g");

            text.append("text")
                .attr("x", 14)
                .attr("y", ".31em")
                .style("font-family", "sans-serif")
                .style("font-size", "0.7em")
                .text(function(d) { return d.id; });

            node.append("title").text(function(d) { return d.id; });

            simulation.nodes(graph.nodes).on("tick", ticked);

            simulation.force("link").links(graph.links);

            function ticked() {
                link
                    .attr("x1", function(d) { return d.source.x; })
                    .attr("y1", function(d) { return d.source.y; })
                    .attr("x2", function(d) { return d.target.x; })
                    .attr("y2", function(d) { return d.target.y; });
                node
                    .attr("cx", function(d) { return d.x; })
                    .attr("cy", function(d) { return d.y; });
                text.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });
            }
        }

        function dragStarted(d) {
            if (!d3.event.active) simulation.alphaTarget(0.3).restart();
            d.fx = d.x;
            d.fy = d.y;
        }

        function dragged(d) {
            d.fx = d3.event.x;
            d.fy = d3.event.y;
        }

        function dragEnded(d) {
            if (!d3.event.active) simulation.alphaTarget(0);
            d.fx = null;
            d.fy = null;
        }

        function zoomed() {
            svg.attr("transform", "translate(" + d3.event.transform.x + "," + d3.event.transform.y + ")" + " scale(" + d3.event.transform.k + ")");
        }

        createGraph(this.props.overviewReducer.graph);
        this.props.animateFauxDOM(1000);
    }

    render () {
        return (
            <div>
            {this.props.overviewReducer.graph == null &&
              <div>
                <h3>No known services...</h3>
                <button onClick={e => this.props.onCreateNew()} className="btn btn-primary">Create one now</button>
              </div>
            }
            {this.props.overviewReducer.graph != null &&
              <div>
                <h2>Services overview</h2>
                <div className='renderedD3'>
                  {this.props.chart}
                </div>
              </div>
            }
            </div>
        );
    }
}

export default withFauxDOM(GraphNetwork);
