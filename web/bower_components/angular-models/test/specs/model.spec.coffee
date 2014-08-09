describe 'angular-models.Model', ->
  model = null
  Model = null
  $rootScope = null
  $httpBackend = null

  beforeEach module 'angular-models'

  beforeEach inject (_Model_, _$rootScope_, _$httpBackend_) ->
    Model = _Model_
    $httpBackend = _$httpBackend_
    model = new Model
    $rootScope = _$rootScope_

  it 'is injectable', ->
    expect(model).to.not.be.undefined

  describe 'mixins', ->
    describe 'LifecycleMixin', ->
      it 'has lifecycle methods', ->
        model.should.have.property 'setLifecycle'
        model.should.have.property 'getLifecycle'
        model.should.have.property 'isLifecycle'
        model.should.have.property 'hasLifecycle'
        model.should.have.property 'isLoaded'
        model.should.have.property 'isDirty'
        model.should.have.property 'isSaving'
        model.should.have.property 'isFetching'
        model.should.have.property 'isDeleted'
        model.should.have.property 'isError'
        model.should.have.property 'isNew'
        model.should.have.property 'isValid'

      it 'saves internal state for lifecycle', ->
        model.setLifecycle 'awesome'
        model._state.should.eql 'awesome'

    describe 'AttributesMixin', ->
      it 'declares attributes in the constructor to ensure state per instance', ->
        model.set 'field1', 'val1'
        model2 = new Model()
        should.not.exist model2.get('field1')

        model2.set 'newfield', 'newval'
        should.not.exist model.get('newfield')

      it 'has toJson alias', ->
        expect(model).to.have.property 'toJson'

    describe 'UrlMixin', ->
      it 'has url methods', ->
        model.should.have.property '_getUrl'

  describe '#constructor', ->

    it 'takes data to deserialize into initial values', ->
      modelJson =
        name: 'awesome'
      model = new Model modelJson
      model.get('name').should.eql modelJson.name

    describe 'url', ->

      it 'takes a string to set as url', ->
        url = "http://apiawesome.com"
        model = new Model url
        model.url.should.eql url

      it 'uses the urlRoot when initing with url', ->
        root = "/api/v2"
        url = "/pages"

        class ModelWithPrefix extends Model
          urlRoot: root

        model = new ModelWithPrefix url
        model._getUrl().should.eql = "#{root}#{url}"

      it 'doesnt double the url root if already included in url', ->
        root = "/api/v2"
        url = "/api/v2/pages"

        class ModelWithPrefix extends Model
          urlRoot: root

        model = new ModelWithPrefix url
        model._getUrl().should.eql url

  describe '#fetch', ->
    url = null

    describe 'Success', ->

      modelJson =
        awesome: 'sauce'

      beforeEach ->
        url = 'awesome'
        model.url = url
        $httpBackend.expectGET(url).respond 200, modelJson

      it 'does an http get to the url string', ->
        model.fetch()
        $httpBackend.flush()

      it 'does an http get to the url function', ->
        model.url = ->
          url
        model.fetch()
        $httpBackend.flush()

      it 'saves data fetched onto attributes', ->
        model.fetch()
        $httpBackend.flush()
        model._attributes.awesome.should.eql 'sauce'

      it 'sets lifecycle state to loaded on success', ->
        model.fetch()
        $httpBackend.flush()
        model.isLoaded().should.be.true

      it 'sets lifecycle state to fetching on request', ->
        model.isFetching().should.be.false
        model.fetch()
        model.isFetching().should.be.true
        $httpBackend.flush()
        model.isFetching().should.be.false

      it 'broadcasts model:fetched event w/ model', ->
        spy = sinon.spy($rootScope, '$broadcast')
        model.fetch()
        $httpBackend.flush()
        spy.should.have.been.calledWith 'model:fetched', model

      it 'broadcasts model:fetched:success event', ->
        spy = sinon.spy($rootScope, '$broadcast')
        model.fetch()
        $httpBackend.flush()
        spy.should.have.been.calledWith 'model:fetched:success', model

    describe 'Error', ->

      beforeEach ->
        url = 'awesome'
        model.url = url

      describe 'W/ errors attr in response', ->

        it 'saves errors', ->
          errorJson =
            errors:
              lame: 'stuff'
          $httpBackend.expectGET(url).respond 422, errorJson
          model.fetch()
          $httpBackend.flush()
          model.errors.lame.should.eql 'stuff'

      describe 'W/o errors attr in response', ->

        errorJson =
          lame: 'stuff'

        beforeEach ->
          $httpBackend.expectGET(url).respond 422, errorJson

        it 'saves errors in fetching onto errors', ->
          model.fetch()
          $httpBackend.flush()
          model.errors.lame.should.eql 'stuff'

        it 'sets lifecycle state to error on error', ->
          model.fetch()
          $httpBackend.flush()
          model.isLoaded().should.be.false
          model.isError().should.be.true

        it 'broadcasts model:fetched event w/ model', ->
          spy = sinon.spy($rootScope, '$broadcast')
          model.fetch()
          $httpBackend.flush()
          spy.should.have.been.calledWith 'model:fetched', model

        it 'broadcasts model:fetched:error event', ->
          spy = sinon.spy($rootScope, '$broadcast')
          model.fetch()
          $httpBackend.flush()
          spy.should.have.been.calledWith 'model:fetched:error', model

    describe 'Jsonp', ->

      modelJson =
        awesome: 'sauce'

      beforeEach ->
        url = 'awesome?callback=JSON_CALLBACK'
        model.url = url
        $httpBackend.expectJSONP(url).respond 200, modelJson

      it 'does an http get via jsonp to the url function', ->
        model.fetch()
        $httpBackend.flush()

      it 'saves data fetched onto attributes', ->
        model.fetch()
        $httpBackend.flush()
        model._attributes.awesome.should.eql 'sauce'

  describe '#deserialize', ->

    it 'calls set by default', ->
      data = { some: 'stuff' }
      spy = sinon.spy(model, 'set')
      model.deserialize data
      spy.should.have.been.calledWith data


  describe '#serialize', ->

    it 'calls toJSON by default', ->
      spy = sinon.spy(model, 'toJSON')
      model.serialize()
      spy.should.have.been.called

  describe '#hasId', ->

    it 'is false if no id', ->
      model.hasId().should.be.false

    it 'is true if id exists', ->
      model.set 'id', 123
      model.hasId().should.be.true

  describe '#save', ->

    url = "superfluous"
    modelJson =
      name : 'sweet'

    beforeEach ->
      model.url = url

    describe 'Post', ->

      describe 'With Data', ->

        beforeEach ->
          $httpBackend.expectPOST(url, modelJson).respond 201, modelJson

        it 'sends attributes in request body', ->
          model.set modelJson
          model.save()
          $httpBackend.flush()

      describe 'Success', ->

        beforeEach ->
          $httpBackend.expectPOST(url).respond 201, modelJson

        it 'posts to url if no id', ->
          model.save()
          $httpBackend.flush()

        it 'sets properties on model after post', ->
          model.save()
          $httpBackend.flush()
          model.get('name').should.eql modelJson.name

        it 'sets lifecycle saving', ->
          model.isSaving().should.be.false
          model.save()
          model.isSaving().should.be.true
          $httpBackend.flush()
          model.isSaving().should.be.false

        it 'sets lifecycle loaded after return', ->
          model.save()
          $httpBackend.flush()
          model.isLoaded().should.be.true

        it 'broadcasts model:saved event w/ model', ->
          spy = sinon.spy($rootScope, '$broadcast')
          model.save()
          $httpBackend.flush()
          spy.should.have.been.calledWith 'model:saved', model

        it 'broadcasts model:saved:success event', ->
          spy = sinon.spy($rootScope, '$broadcast')
          model.save()
          $httpBackend.flush()
          spy.should.have.been.calledWith 'model:saved:success'

      describe 'Error', ->

        describe 'W/ errors attr in response', ->

          it 'saves errors', ->
            errorJson =
              errors:
                lame: 'stuff'
            $httpBackend.expectPOST(url).respond 422, errorJson
            model.save()
            $httpBackend.flush()
            model.errors.lame.should.eql 'stuff'

        describe 'W/o errors attr in response', ->

          errorJson =
            lame: 'stuff'

          beforeEach ->
            $httpBackend.expectPOST(url).respond 422, errorJson

          it 'saves errors in saving onto errors', ->
            model.save()
            $httpBackend.flush()
            model.errors.lame.should.eql 'stuff'

          it 'sets lifecycle state to error on error', ->
            model.save()
            $httpBackend.flush()
            model.isLoaded().should.be.false
            model.isError().should.be.true

          it 'broadcasts model:saved event w/ model', ->
            spy = sinon.spy($rootScope, '$broadcast')
            model.save()
            $httpBackend.flush()
            spy.should.have.been.calledWith 'model:saved', model

          it 'broadcasts model:saved:error event', ->
            spy = sinon.spy($rootScope, '$broadcast')
            model.save()
            $httpBackend.flush()
            spy.should.have.been.calledWith 'model:saved:error'

    describe 'Put', ->

      beforeEach ->
        $httpBackend.expectPUT(url).respond 200, modelJson
        model.set 'id', 123

      it 'puts to url if already has id', ->
        model.save()
        $httpBackend.flush()

  describe '#destroy', ->

    url = "cabbage"
    modelJson =
      name : 'sweet'

    beforeEach ->
      model.url = url

    describe 'Success', ->

      beforeEach ->
        $httpBackend.expectDELETE(url).respond 204

      it 'sends delete to url', ->
        model.destroy()
        $httpBackend.flush()

      it 'sets lifecycle saving', ->
        model.isSaving().should.be.false
        model.destroy()
        model.isSaving().should.be.true
        $httpBackend.flush()
        model.isSaving().should.be.false

      it 'sets lifecycle deleted after return', ->
        model.destroy()
        $httpBackend.flush()
        model.isDeleted().should.be.true

      it 'broadcasts model:destroyed event w/ model', ->
        spy = sinon.spy($rootScope, '$broadcast')
        model.destroy()
        $httpBackend.flush()
        spy.should.have.been.calledWith 'model:destroyed', model

      it 'broadcasts model:destroyed:success event', ->
        spy = sinon.spy($rootScope, '$broadcast')
        model.destroy()
        $httpBackend.flush()
        spy.should.have.been.calledWith 'model:destroyed:success'

    describe 'Error', ->

      describe 'W/ errors attr in response', ->

        it 'saves errors', ->
          errorJson =
            errors:
              lame: 'stuff'
          $httpBackend.expectDELETE(url).respond 422, errorJson
          model.destroy()
          $httpBackend.flush()
          model.errors.lame.should.eql 'stuff'

      describe 'W/o errors attr in response', ->

        errorJson =
          lame: 'stuff'

        beforeEach ->
          $httpBackend.expectDELETE(url).respond 422, errorJson

        it 'saves errors in destroying onto errors', ->
          model.destroy()
          $httpBackend.flush()
          model.errors.lame.should.eql 'stuff'

        it 'sets lifecycle state to error on error', ->
          model.destroy()
          $httpBackend.flush()
          model.isLoaded().should.be.false
          model.isError().should.be.true

        it 'broadcasts model:destroyed event w/ model', ->
          spy = sinon.spy($rootScope, '$broadcast')
          model.destroy()
          $httpBackend.flush()
          spy.should.have.been.calledWith 'model:destroyed', model

        it 'broadcasts model:destroyed:error event', ->
          spy = sinon.spy($rootScope, '$broadcast')
          model.destroy()
          $httpBackend.flush()
          spy.should.have.been.calledWith 'model:destroyed:error'
