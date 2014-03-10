"use strict"

app.directive 'd3Graph', (d3Service) ->

  restrict: 'EA'

  scope:
    data: "=d3GraphData"
    load: "=d3GraphLoad"

  link: (scope, ele) ->

    d3Service.d3().then (d3) ->

      svg = d3.select(ele[0])
      .append('svg')
      .attr(
          width: "100%"
          height: "500%"
        )

      scope.$watch "data", (-> render scope.data)

      links = []
      nodes = []

      link = null
      node = null

      force = d3.layout.force()
      .charge(-500)
      .linkDistance(30)
      .linkStrength(0.1)
      .size([500, 500])
      .nodes(nodes)
      .links(links)
      .on "tick", ->
          #console.log "tick", link
          link.attr("x1", (d) -> d.source.x)
          .attr("y1", (d) -> d.source.y)
          .attr("x2", (d) -> d.target.x)
          .attr("y2", (d) -> d.target.y)
          node.attr "transform", (d) -> "translate(" + d.x + "," + d.y + ")"

      _getLinkIndex = (d, index) ->
        idx = force.links().indexOf force.links().filter((f) -> f.attrs.key == d.attrs.key)[0]
        console.log "links", idx, index
        idx = index if idx == -1
        idx

      _getNodeIndex = (d, index) ->
        idx = force.nodes().indexOf force.nodes().filter((f) -> f.attrs.id == d.attrs.id)[0]
        console.log "nodes", idx, index
        idx = index if idx == -1
        idx

      render = (data) ->

        if !data then return

        for lk in data.links
          keys = [lk.source.attrs.id, lk.target.attrs.id].sort(d3.ascending)
          lk.attrs.key = keys[0] + "_" + keys[1]
          existentNode = force.nodes().filter((f) -> f.attrs.id == lk.target.attrs.id)[0]
          if existentNode
            lk.target = existentNode
          existentNode = force.nodes().filter((f) -> f.attrs.id == lk.source.attrs.id)[0]
          if existentNode
            lk.source = existentNode

        force.links().push data.links...
        force.nodes().push data.nodes...

        link = svg.selectAll(".link")
        .data(force.links(), _getLinkIndex)
        .enter()
        .append("line")
        .attr("class", "link")

        node = svg.selectAll(".node")
        .data(force.nodes(), _getNodeIndex)
        .enter()
        .append("g")

        node
        .append("circle")
        .attr("class", (n) -> "node node-#{n.attrs.type}")
        .attr("r", 10)

        node
        .call(force.drag)

        node
        .on("dblclick", (n) ->
            scope.load n.attrs.id
          )

        node
        .append("text")
        .attr("class", "text")
        .style("text-anchor", "middle")
        .text((d) -> d.attrs.label)


        link = svg.selectAll(".link")
        node = svg.selectAll("g")

        node.sort -> -1
        link.sort -> -1

        force.start()
