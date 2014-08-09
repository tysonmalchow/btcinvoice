angular.module('angular-models').service 'NameMixin', ->

  # TODO: this doesn't work that great - maybe remove it?
  # consider: http://stackoverflow.com/questions/332422/how-do-i-get-the-name-of-an-objects-type-in-javascript
  name: ->
    @constructor?.name?.toLowerCase() || 'model'

  _getName: () ->
    _.result(@, 'name')
