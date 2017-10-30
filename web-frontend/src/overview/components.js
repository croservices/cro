import ReactDOM from 'react-dom';
import React from 'react';
import * as d3 from 'd3';

class GraphNetwork extends React.Component {
    constructor (props) {
        super(props);
    }

    render () {
        return (
                <div>
                <h3>Overview</h3>
                <svg ref={node => this.node = node} width={this.width} height={this.height}></svg>
                </div>
        )
    }

    renderD3(graph) {
        if (graph == null) return;

        const element = this.node;
        var color = d3.scaleOrdinal(d3.schemeCategory10);

        var simulation = d3.forceSimulation()
            .force("link", d3.forceLink().id(function(d) { return d.id; }))
            .force("attract", d3.forceManyBody().strength(80).distanceMax(400).distanceMin(100))
            .force("collide", d3.forceCollide(40).strength(1).iterations(1))
            .force("center", d3.forceCenter(this.width / 2, this.height / 2));

        var node = d3.select(element)
            .selectAll("circle")
            .data(graph.nodes)
            .enter().append("circle")
            .attr("r", 10)
            .attr("fill", function(d) { if (d.root == "true") return color(d.root); return color(d.type); });

        var link = d3.select(element)
            .selectAll("line")
            .data(graph.links)
            .enter().append("line")
            .attr("stroke", function(d) { return color(d.type); });
        var text = d3.select(element)
            .selectAll("g")
            .data(graph.nodes)
            .enter().append("g");

        text.append("text")
            .attr("x", 14)
            .attr("y", ".31em")
            .style("font-family", "inherit")
            .style("font-size", "1em")
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

    componentWillMount() {
        this.width = 500;
        this.height = 500;
    }

    componentDidMount () {
        this.renderD3(this.props.overviewReducer.graph);
    }

    shouldComponentUpdate (props) {
        this.renderD3(props.overviewReducer.graph);
        return false;
    }
};

export default GraphNetwork;
