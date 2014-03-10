"use strict"

d3app.factory 'd3Service', ($document, $q, $rootScope, D3JS_SCRIPT_PATH) ->
  d = $q.defer()
  onScriptLoad = ->
    $rootScope.$apply -> d.resolve(window.d3)
  scriptTag = $document[0].createElement('script')
  scriptTag.type = 'text/javascript';
  scriptTag.async = true;
  scriptTag.src = D3JS_SCRIPT_PATH
  scriptTag.onreadystatechange = ->
    if this.readyState == 'complete' then onScriptLoad()
  scriptTag.onload = onScriptLoad
  s = $document[0].getElementsByTagName('body')[0]
  s.appendChild(scriptTag)

  d3: -> d.promise

