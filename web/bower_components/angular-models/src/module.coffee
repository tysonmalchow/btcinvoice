# based on http:#arcturo.github.io/library/coffeescript/03_classes.html
angular.module('angular-models').factory 'Module', ->

  moduleKeywords = ['included', 'dependencies']

  class Module

    _dependencyFns: []

    constructor: (data) ->
      fn.apply @ for fn in @_dependencyFns if @_dependencyFns?

    @include: (obj) ->
      for key, value of obj when key not in moduleKeywords
        @::[key] = value

      @::_dependencyFns.push(obj.dependencies) if obj.dependencies?

      obj.included?.apply(@)
      @

  Module