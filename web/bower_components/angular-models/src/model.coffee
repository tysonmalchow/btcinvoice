angular.module('angular-models').factory 'Model', ($rootScope, $http, Module, NameMixin, Lifecycle, AttributesMixin, UrlMixin) ->

  class Model extends Module
    @include NameMixin
    @include Lifecycle
    @include AttributesMixin
    @include UrlMixin

    constructor: (data) ->
      super data
      @errors = {}

      if data?
        if _.isString data
          @url = data
        else
          @set data

    fetch: =>
      name = @_getName()

      success = (data) =>
        @deserialize data
        @setLifecycle 'loaded'
        $rootScope.$broadcast "#{name}:fetched", @
        $rootScope.$broadcast "#{name}:fetched:success", @

      error = (data) =>
        @_saveErrors data
        @setLifecycle 'error'
        $rootScope.$broadcast "#{name}:fetched", @
        $rootScope.$broadcast "#{name}:fetched:error", @

      method = if @_getUrl()?.indexOf('callback=JSON_CALLBACK') > -1 then 'jsonp' else 'get'
      @setLifecycle 'fetching'
      $http[method](@_getUrl()).success(success).error(error)

    save: =>
      name = @_getName()

      success = (data) =>
        @deserialize data
        @setLifecycle 'loaded'
        $rootScope.$broadcast "#{name}:saved", @
        $rootScope.$broadcast "#{name}:saved:success"

      error = (data) =>
        @_saveErrors data
        @setLifecycle 'error'
        $rootScope.$broadcast "#{name}:saved", @
        $rootScope.$broadcast "#{name}:saved:error"

      method = if @hasId() then 'put' else 'post'
      @setLifecycle 'saving'
      $http[method](@_getUrl(), @serialize()).success(success).error(error)

    destroy: =>
      name = @_getName()

      success = (data) =>
        @deserialize data
        @setLifecycle 'deleted'
        $rootScope.$broadcast "#{name}:destroyed", @
        $rootScope.$broadcast "#{name}:destroyed:success"

      error = (data) =>
        @_saveErrors data
        @setLifecycle 'error'
        $rootScope.$broadcast "#{name}:destroyed", @
        $rootScope.$broadcast "#{name}:destroyed:error"

      @setLifecycle 'saving'
      $http.delete(@_getUrl()).success(success).error(error)

    toJson: @::toJSON #alias

    deserialize: (data) ->
      @set data

    serialize: ->
      @toJSON()

    hasId: ->
      @get('id')?

    _saveErrors: (data) ->
      _.extend @errors, if data?.errors? then data.errors else data

  Model
