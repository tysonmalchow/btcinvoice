describe 'angular-models.Collection', ->
  collection = null
  Collection = null
  Model = null

  $rootScope = null
  $httpBackend = null

  modelsJson = [
    { id: 1, name: 'One' }
    { id: 2, name: 'Two' }
    { id: 3, name: 'Three' }
  ]

  beforeEach module 'angular-models'

  beforeEach inject (_Collection_, _$rootScope_, _$httpBackend_, _Model_) ->
    Collection = _Collection_
    Model = _Model_
    $rootScope = _$rootScope_
    $httpBackend = _$httpBackend_

  it 'is injectable', ->
    expect(Collection).to.not.be.undefined

  describe 'mixins', ->
    collection = null

    beforeEach ->
      collection = new Collection

    describe 'LifecycleMixin', ->
      it 'has lifecycle methods', ->
        collection.should.have.property 'setLifecycle'
        collection.should.have.property 'getLifecycle'
        collection.should.have.property 'isLifecycle'
        collection.should.have.property 'hasLifecycle'
        collection.should.have.property 'isLoaded'
        collection.should.have.property 'isDirty'
        collection.should.have.property 'isSaving'
        collection.should.have.property 'isFetching'
        collection.should.have.property 'isDeleted'
        collection.should.have.property 'isError'
        collection.should.have.property 'isNew'
        collection.should.have.property 'isValid'

      it 'saves internal state for lifecycle', ->
        collection.setLifecycle 'awesome'
        collection._state.should.eql 'awesome'

    describe 'UrlMixin', ->
      it 'has url methods', ->
        collection.should.have.property '_getUrl'

  describe '#constructor', ->

    it 'takes data to initialize the collection with', ->
      collection = new Collection modelsJson
      collection.models.length.should.eql modelsJson.length

    it 'starts with length of 0', ->
      collection = new Collection
      collection.length.should.eql 0

  describe '#add', ->

    beforeEach ->
      collection = new Collection

    it 'handles a null', ->
      collection.add()
      collection.models.length.should.eql 0

    it 'creates a model with the given json', ->
      modelJson =
        name: 'Scottly'
      collection.add modelJson
      collection.models[0].name().should.eql 'model'

    it 'adds the model to the internal models array', ->
      collection.add {}
      _.isArray(collection.models).should.be.true
      collection.models.length.should.eql 1

    it 'has a push alias', ->
      collection.should.have.property 'push'

    it 'increases the length by one', ->
      collection.add { stuff: 'here' }
      collection.length.should.eql 1
      collection.add { something: 'else' }
      collection.length.should.eql 2

    it 'doesnt allow duplicate entry based on equality', ->
      collection.add modelsJson[0]
      collection.length.should.eql 1
      collection.add modelsJson[0]
      collection.length.should.eql 1

    it 'adds already-instantiated models straight to models array', ->
      model = new Model { id: 1 }
      collection.add model
      collection.models[0].toJSON().constructor.name.should.not.equal 'Model'
      collection.models[0].toJSON().constructor.name.should.equal 'Object'

  describe '#fetch', ->
    collection = null
    collectionName = 'stuffs'
    url = '/getting/sweet/models'

    beforeEach ->
      class MockCollection extends Collection
        name: collectionName
        url: url

      collection = new MockCollection

    describe 'successful request', ->
      responseJson = {}
      responseJson[collectionName] = [{
          id: 1
          value: 'one'
        }, {
          id: 2
          value: 'two'
        }, {
          id: 3
          value: 'three'
        }]

      beforeEach ->
        $httpBackend.expectGET(url).respond 200, responseJson

      it 'does an http get to the url', ->
        collection.fetch()
        $httpBackend.flush()

      it 'sets lifecycle state to fetching on request', ->
        collection.isFetching().should.be.false
        collection.fetch()
        collection.isFetching().should.be.true
        $httpBackend.flush()

      it 'sets lifecycle state to loaded on response', ->
        collection.fetch()
        $httpBackend.flush()
        collection.isLoaded().should.be.true

      it 'resets collection with returned data', ->
        collection.fetch()
        $httpBackend.flush()

        collection.models.length.should.eql responseJson[collectionName].length
        for model, i in collection.models
          model.toJSON().should.eql responseJson[collectionName][i]

      it 'broadcasts collection:fetched event w/ collection', ->
        spy = sinon.spy($rootScope, '$broadcast')
        collection.fetch()
        $httpBackend.flush()
        spy.should.have.been.calledWith "#{collectionName}:fetched", collection

      it 'broadcasts model:fetched:success event', ->
        spy = sinon.spy($rootScope, '$broadcast')
        collection.fetch()
        $httpBackend.flush()
        spy.should.have.been.calledWith "#{collectionName}:fetched:success", collection

    describe 'failed request', ->
      beforeEach ->
        $httpBackend.expectGET(url).respond 422

      it 'sets lifecycle state to error on response', ->
        collection.fetch()
        $httpBackend.flush()
        collection.isError().should.be.true

      it 'broadcasts collection:fetched event w/ collection', ->
        spy = sinon.spy($rootScope, '$broadcast')
        collection.fetch()
        $httpBackend.flush()
        spy.should.have.been.calledWith "#{collectionName}:fetched", collection

      it 'broadcasts model:fetched:error event', ->
        spy = sinon.spy($rootScope, '$broadcast')
        collection.fetch()
        $httpBackend.flush()
        spy.should.have.been.calledWith "#{collectionName}:fetched:error", collection

  describe '#remove', ->

    Model = null

    beforeEach inject (_Model_) ->
      Model = _Model_
      collection = new Collection modelsJson

    it 'handles null', ->
      collection.remove()
      collection.models.length.should.eql 3

    it 'removes model based on equality', ->
      collection.remove collection.models[0]
      collection.models.length.should.eql 2
      for model, i in collection.models
        model.toJSON().should.eql modelsJson[i + 1]

    it 'removes model based on json id', ->
      collection.remove { id: modelsJson[0].id }
      collection.models.length.should.eql 2
      for model, i in collection.models
        model.toJSON().should.eql modelsJson[i + 1]

    it 'removes model based on model id', ->
      collection.remove new Model modelsJson[0]
      collection.models.length.should.eql 2
      for model, i in collection.models
        model.toJSON().should.eql modelsJson[i + 1]

    it 'decreases length by one', ->
      collection.length.should.eql modelsJson.length
      collection.remove modelsJson[0]
      collection.length.should.eql modelsJson.length - 1

  describe '#reset', ->

    it 'blanks out models if no data given', ->
      collection = new Collection modelsJson
      collection.models.length.should.eql modelsJson.length
      collection.reset()
      collection.models.length.should.eql 0

    it 'sets length to zero', ->
      collection = new Collection modelsJson
      collection.length.should.eql modelsJson.length
      collection.reset()
      collection.length.should.eql 0

    it 'sets data', ->
      collection = new Collection
      collection.length = 0
      collection.reset modelsJson
      collection.models.length.should.eql modelsJson.length
      for model, i in collection.models
        model.toJSON().should.eql modelsJson[i]

  describe '#hasModels', ->

    beforeEach ->
      collection = new Collection

    it 'has a method to test that it is a collection', ->
      collection.should.have.property 'hasModels'

  describe '#eq', ->

    it 'will return model at given index', ->
      collection = new Collection
      model1 = new Model
      model2 = new Model
      collection.add model1
      collection.add model2
      collection.eq(0).should.eql model1
      collection.eq(1).should.eql model2

  describe '#first', ->

    it 'will always return the first model', ->
      collection = new Collection
      model1 = new Model
      model2 = new Model
      collection.add model1
      collection.first().should.eql model1
      collection.add model2
      collection.first().should.eql model1

  describe '#last', ->

    it 'will always return the last model', ->
      collection = new Collection
      model1 = new Model
      model2 = new Model
      collection.add model1
      collection.last().should.eql model1
      collection.add model2
      collection.last().should.eql model2

