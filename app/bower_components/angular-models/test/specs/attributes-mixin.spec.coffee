describe 'angular-models.AttributesMixin', ->
  AttributesMixin = null
  Module = null
  Collection = null
  TestModel = null
  model = null

  beforeEach module 'angular-models'

  beforeEach inject (_AttributesMixin_, _Module_, _Collection_) ->
    AttributesMixin = _AttributesMixin_
    Collection = _Collection_
    Module = _Module_

    class TestModel extends Module
      @include AttributesMixin
      constructor: (data) ->
        super data

    model = new TestModel

  it 'is injectable', ->
    expect(AttributesMixin).to.not.be.undefined

  it 'has an api', ->
    expect(AttributesMixin).to.have.property 'set'
    expect(AttributesMixin).to.have.property 'get'
    expect(AttributesMixin).to.have.property 'getModels'
    expect(AttributesMixin).to.have.property 'toJSON'
    expect(AttributesMixin).to.have.property 'hasAttributes'

  describe '#dependencies', ->

    it 'doesnt start with attributes', ->
      mixin = AttributesMixin
      mixin.should.not.have.property 'attributes'

    it 'sets attributes after dependencies() is called', ->
      mixin = AttributesMixin
      mixin.dependencies()
      mixin.should.have.property '_attributes'

  describe '#get and #set', ->

    it 'sets and gets values from attributes', ->
      model.set 'awesome', 'stuff'
      model.get('awesome').should.eql 'stuff'

    it 'sets multiple values', ->
      model.set
        super: 'duper'
        stuff: 'here'
      model.get('super').should.eql 'duper'
      model.get('stuff').should.eql 'here'

    it 'sets 1 level inner json with dot syntax on something already set', ->
      model.set 'something', {}
      model.set 'something.inside', 'innerval'
      model.get('something').inside.should.eql 'innerval'

    it 'gets 1 level inner json with dot syntax', ->
      model.set 'something.inside', 'innerval'
      model.get('something.inside').should.eql 'innerval'

    it 'gets 1 level inner json with dot syntax thats not defined', ->
      should.not.exist model.get('something.inside')

    it 'sets 2 level inner json with dot syntax on something already set', ->
      model.set 'something', { inside: {} }
      model.set 'something.inside.more', 'innerval'
      model.get('something').inside.more.should.eql 'innerval'

    it 'gets 2 level inner json with dot syntax', ->
      model.set 'something.inside.more', 'innerval'
      model.get('something.inside.more').should.eql 'innerval'

    it 'sets 2 level inner json with dot syntax on something not set', ->
      model.set 'something', {}
      model.set 'something.inside.more', 'innerval'
      model.get('something').inside.more.should.eql 'innerval'

    it 'sets 1 level inner model with dot syntax on something already set', ->
      model.set 'something', new TestModel
      model.set 'something.inside', 'innerval'
      model.get('something').get('inside').should.eql 'innerval'

    it 'gets 1 level inner model with dot syntax', ->
      model.set 'something', new TestModel
      model.set 'something.inside', 'innerval'
      model.get('something.inside').should.eql 'innerval'

    it 'sets 2 level inner model with dot syntax on something already set', ->
      model3 = new TestModel
      model3.set 'more', 'innerval'
      model2 = new TestModel
      model2.set 'inside', model3
      model.set 'something', model2

      model.set 'something.inside.more', 'innerval'
      model.get('something').get('inside').get('more').should.eql 'innerval'

    it 'gets 2 level inner model with dot syntax', ->
      model3 = new TestModel
      model3.set 'more', 'innerval'
      model2 = new TestModel
      model2.set 'inside', model3
      model.set 'something', model2

      model.set 'something.inside.more', 'innerval'
      model.get('something.inside.more').should.eql 'innerval'

  describe '#hasAttributes', ->

    it 'is true if has attributes', ->
      model.hasAttributes().should.be.true

  describe '#toJSON()', ->

    it 'handles 1-level json', ->
      json =
        super: 'duper'
      model.set json
      model.toJSON().should.eql json

    it 'handles nested json', ->
      json =
        super:
          nested: 'val'
      model.set json
      model.toJSON().should.eql json

    describe 'Nested models', ->

      it 'returns pure json for nested model 1 field', ->

        model2 = new TestModel
        model2.set 'field1', 'val1'

        model.set 'innermodel', model2

        expectedJson =
          innermodel:
            field1: 'val1'
        model.toJSON().should.eql expectedJson

      it 'returns pure json for double nested model 1 field', ->

        model3 = new TestModel
        model3.set 'field1', 'val1'

        model2 = new TestModel
        model2.set 'nextinnermodel', model3

        model.set 'innermodel', model2

        expectedJson =
          innermodel:
            nextinnermodel:
              field1: 'val1'

        model.toJSON().should.eql expectedJson

      it 'returns pure json for nested model 2 fields', ->

        model2 = new TestModel
        model2.set 'field1', 'val1'

        model.set 'innermodel', model2
        model.set 'siblinginnermodel', model2

        expectedJson =
          innermodel:
            field1: 'val1'
          siblinginnermodel:
            field1: 'val1'

        model.toJSON().should.eql expectedJson

      it 'returns pure json for array of nested model', ->

        model3 = new TestModel
        model3.set 'field2', 'val2'

        model2 = new TestModel
        model2.set 'field1', 'val1'

        model.set 'innermodels', [ model2, model3 ]

        expectedJson =
          innermodels: [
            { field1: 'val1' }
            { field2: 'val2' }
          ]

        model.toJSON().should.eql expectedJson

      it 'returns pure json for array of nested model with nested model', ->

        model4 = new TestModel
        model4.set 'field2', 'val2'

        model3 = new TestModel
        model3.set 'innerermodel', model4

        model2 = new TestModel
        model2.set 'field1', 'val1'

        model.set 'innermodels', [ model2, model3 ]

        expectedJson =
          innermodels: [
            { field1: 'val1' }
            { innerermodel: { field2: 'val2' } }
          ]

        model.toJSON().should.eql expectedJson

      it 'returns an array of non-object items', ->
        model.set 'myarray', ['one', 'two', 'three']
        expectedJson =
          myarray: [
            "one"
            "two"
            "three"
          ]

        model.toJSON().should.eql expectedJson

      describe 'With Collections', ->

        it 'returns json a model with a collection', ->
          collection = new Collection
          collection.add { field1: 'val1' }
          collection.add { field2: 'val2' }

          model.set 'posts', collection

          expectedJson =
            posts: [
              { field1: 'val1'}
              { field2: 'val2'}
            ]

          model.toJSON().should.eql expectedJson

  describe '#getModels', ->

    it 'returns models if hasModels', ->
      json = [new TestModel { id: 1 }, new TestModel { id: 2 }]
      model.set 'manyThings', new Collection json
      model.getModels('manyThings').should.eql json

  describe '#clear', ->

    it 'removes all attributes', ->
      model.set
        id: 1
        stuff: 'here'
      Object.keys(model._attributes).length.should.eql 2
      model.clear()
      Object.keys(model._attributes).length.should.eql 0


