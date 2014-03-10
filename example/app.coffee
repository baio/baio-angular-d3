"use strict"

d3app = angular.module('d3', ['ngResource'])

d3app.factory 'd3Service', ($document, $q, $rootScope) ->
  d = $q.defer()
  onScriptLoad = ->
    $rootScope.$apply -> d.resolve(window.d3)
  scriptTag = $document[0].createElement('script')
  scriptTag.type = 'text/javascript';
  scriptTag.async = true;
  scriptTag.src = 'src/d3.v3.min.js'
  scriptTag.onreadystatechange = ->
    if this.readyState == 'complete' then onScriptLoad()
  scriptTag.onload = onScriptLoad
  s = $document[0].getElementsByTagName('body')[0]
  s.appendChild(scriptTag)

  d3: -> d.promise


app = angular.module('app', ['d3'])

app.directive 'd3Bars', (d3Service) ->

  restrict: 'EA'
  scope: {}

  link: (scope, ele, attrs) ->

    margin = parseInt(attrs.margin) || 20
    barHeight = parseInt(attrs.barHeight) || 20
    barPadding = parseInt(attrs.barPadding) || 5

    d3Service.d3().then (d3) ->
      svg = d3.select(ele[0])
        .append('svg')
        .style('width', '100%')

      window.onresize = -> scope.$apply()

      scope.data = [
        {name: "Greg", score: 98},
        {name: "Ari", score: 96},
        {name: 'Q', score: 75},
        {name: "Loser", score: 48}
      ]

      scope.$watch (-> angular.element(window)[0].innerWidth), (-> scope.render scope.data)

      scope.render = (data) ->

        console.log data

        svg.selectAll('*').remove()

        if !data then return

        width = d3.select(ele[0]).node().offsetWidth - margin
        height = scope.data.length * (barHeight + barPadding)
        color = d3.scale.category20()
        xScale = d3.scale.linear()
        .domain([0, d3.max(data, (d) -> d.score)])
        .range([0, width])

        svg.attr('height', height)

        svg.selectAll('rect')
          .data(data).enter()
          .append('rect')
          .attr('height', barHeight)
          .attr('width', 140)
          .attr('x', Math.round(margin/2))
          .attr('y', (d,i) -> i * (barHeight + barPadding))
          .attr('fill', (d) -> color(d.score))
          .transition()
          .duration(1000)
          .attr('width', (d) -> xScale(d.score))



app.factory "graphDataProvider", ($resource, $q) ->

  resource = $resource("//localhost:8080/api/graph/people/:id", {id : "@id"})

  map = (graph) ->

    nodes = _.flatten graph.map (m) -> [{attrs : m.fromNode}, {attrs : m.toNode}]
    nodes = _.uniq nodes, (n) -> n.attrs.id

    links = graph.map (m) ->
      attrs :
        id : m.id
        label : m.label
      source : nodes.filter((f) -> m.fromNode.id == f.attrs.id)[0]
      target : nodes.filter((f) -> m.toNode.id == f.attrs.id)[0]

    nodes : nodes
    links : links

  load : (id) ->
    deferred = $q.defer()
    resource.query id : id, (graph_data) ->
      data = map graph_data
      deferred.resolve data
    , (err) ->
        deferred.reject err
    deferred.promise

app.directive 'd3Graph', (d3Service) ->

  restrict: 'EA'

  scope:
    data: "=d3GraphData"
    load: "=d3GraphLoad"

  link: (scope, ele) ->
    #http://stackoverflow.com/questions/11606214/adding-and-removing-nodes-in-d3js-force-graph

    d3Service.d3().then (d3) ->

      svg = d3.select(ele[0])
      .append('svg')
      .attr("width", 500)
      .attr("height", 500)

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


        ###
        console.log "--------"

        console.log link
        console.log node

        link = svg.selectAll(".link")
        node = svg.selectAll("g")

        console.log link
        console.log node
        ###
        link = svg.selectAll(".link")
        node = svg.selectAll("g")

        node.sort -> -1
        link.sort -> -1

        force.start()



app.controller "mainController", ($scope, graphDataProvider) ->

  $scope.graph = null

  $scope.loadGraph = (id) ->
    graphDataProvider.load(id).then (data) ->
      $scope.graph = data

  $scope.loadGraph(133)