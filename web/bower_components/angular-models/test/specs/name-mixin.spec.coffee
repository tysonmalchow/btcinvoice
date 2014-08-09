describe 'angular-models.NameMixin', ->
  NameMixin = null
  Module = null

  beforeEach module 'angular-models'

  beforeEach inject (_NameMixin_, _Module_) ->
    NameMixin = _NameMixin_
    Module = _Module_

  it 'is injectable', ->
    expect(NameMixin).to.exist

  it 'has an api', ->
    expect(NameMixin).to.have.property '_getName'

  describe '#_getName', ->
    it 'returns the class name', ->
      name = 'awesome name'

      class TestModel extends Module
        @include NameMixin
        name: name

      model = new TestModel

      model._getName().should.eql name

    it 'returns the class name from a function', ->
      name = 'more awesome name'

      class TestModel extends Module
        @include NameMixin
        name: -> name

      model = new TestModel

      model._getName().should.eql name
