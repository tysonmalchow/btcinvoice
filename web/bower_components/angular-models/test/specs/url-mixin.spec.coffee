describe 'angular-models.UrlMixin', ->
  UrlMixin = null
  Module = null

  model = null

  beforeEach module 'angular-models'

  beforeEach inject (_UrlMixin_, _AttributesMixin_, _Module_) ->
    UrlMixin = _UrlMixin_
    Module = _Module_

    class TestModel extends Module
      @include _AttributesMixin_
      @include UrlMixin

      constructor: (data) ->
        super data

    model = new TestModel

  it 'is injectable', ->
    expect(UrlMixin).to.exist

  it 'has an api', ->
    expect(UrlMixin).to.have.property '_getUrl'

  describe '#_getUrl', ->
    it 'takes a string to set as url', ->
      url = "http://apiawesome.com"
      model.url = url
      model.url.should.eql url

    it 'takes a function to use as url', ->
      model.url = -> '/resource'
      model._getUrl().should.eql "/resource"

    it 'resolves named parameters in url', ->
      model.set 'id', 123
      model.url = "/posts/:id"
      model._getUrl().should.eql "/posts/123"

    it 'prepends the urlRoot', ->
      model.urlRoot = '/api/v2'
      model.url = '/resource'

      model._getUrl().should.eql '/api/v2/resource'

    it 'doesnt double the url root if already included in url', ->
      model.urlRoot = '/api/v10'
      model.url = '/api/v10/donuts'

      model._getUrl().should.eql '/api/v10/donuts'
