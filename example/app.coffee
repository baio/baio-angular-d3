"use strict"

app = angular.module('app', ['baio.d3', 'ngResource'])

app.constant("D3JS_SCRIPT_PATH", "../bower_components/d3/d3.min.js")

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


app.controller "mainController", ($scope, graphDataProvider) ->

  $scope.graph = null

  $scope.loadGraph = (id) ->
    graphDataProvider.load(id).then (data) ->
      $scope.graph = data

  $scope.loadGraph(133)