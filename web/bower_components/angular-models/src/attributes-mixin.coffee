angular.module('angular-models').service 'AttributesMixin',  ->

  dependencies: ->
    @_attributes = {}

  hasAttributes: ->
    @_attributes?

  set: (key, val) ->
    if @_isMultilevelString key
      keys = key.split /\./
      obj = @_crawlObjects @_attributes, keys
      if obj.hasAttributes?()
        obj.set keys[keys.length - 1], val
      else
        obj[keys[keys.length - 1]] = val

    else
      if _.isObject(key)
        attrs = key
      else
        (attrs = {})[key] = val

      @_attributes[attr] = val for attr, val of attrs

    @

  get: (key) ->
    if @_isMultilevelString key
      keys = key.split /\./
      obj = @_crawlObjects @_attributes, keys
      if obj.hasAttributes?()
        obj.get keys[keys.length - 1]
      else
        obj[keys[keys.length - 1]]
    else
      @_attributes[key]

  clear: ->
    @_attributes = {}

  getModels: (key) ->
    if @_attributes[key]?.hasModels?()
      @_attributes[key].models
    else
      @get key

  toJSON: ->
    json = {}
    for attr, val of @_attributes
      if _.isArray val
        json[attr] = []
        for arrVal in val
          json[attr].push if arrVal.toJSON? then arrVal.toJSON() else arrVal
      else if val?.hasModels?()
        json[attr] = []
        json[attr].push(arrVal.toJSON?()) for arrVal in val.models
      else if val?.hasAttributes?()
        json[attr] = val.toJSON?()
      else
        json[attr] = val
    json

  # build obj in chain if doesn't exist
  _ensureObject: (obj, keys) ->
    if obj.hasAttributes?()
      attr = obj.get(keys[0])
      if not attr
        attr = obj.set keys[0], {}
    else
      attr = obj[keys[0]]
      if not attr
        attr = obj[keys[0]] = {}
    attr

  _crawlObjects: (obj, keys) ->
    if keys.length <= 1 # leave last key for val assignment
      return obj
    @_crawlObjects @_ensureObject(obj, keys), keys[1..]

  _isMultilevelString: (key) ->
    _.isString(key) and key.match /\./


