angular.module('angular-models').service 'UrlMixin', ($filter) ->

  dependencies: ->
    # temp fix for follow while the api doesn't include proxy prefixes (eg, /api/v2)
    @urlRoot ?= ""

  _getUrl: ->
    url = _.result(@, 'url')

    urlWithRoot = if url?.indexOf(@urlRoot) > -1
      url
    else
      "#{@urlRoot}#{url}"

    $filter('linkTo')(urlWithRoot, @)
