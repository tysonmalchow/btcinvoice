describe 'angular-models.Module', ->
  TestModule = null

  beforeEach module 'angular-models'

  beforeEach inject (Module) ->
    class TestModule extends Module

  describe '#constructor', ->

    it 'applies all dependency functions', ->
      oneCalled = false
      twoCalled = false
      one = ->
        oneCalled = true
      two = ->
        twoCalled = true
      TestModule::_dependencyFns = [ one, two ]

      new TestModule

      oneCalled.should.be.true
      twoCalled.should.be.true

  describe '#include', ->

    mixin =
      mixinFnOne: ->
      mixinFnTwo: ->

    mixinWithDeps =
      dependencies: ->
      mixinFnOne: ->
      mixinFnTwo: ->

    it 'puts mixin functions on the module prototype', ->
      TestModule.include mixin
      TestModule::should.have.property 'mixinFnOne'
      TestModule::should.have.property 'mixinFnTwo'

    it 'handles mixins with no dependencies', ->
      TestModule.include mixin
      TestModule::_dependencyFns.length.should.eql 0

    it 'does not add dependencies to prototype', ->
      TestModule.include mixinWithDeps
      TestModule::should.not.have.property 'dependencies'

    it 'saves references to dependencies function', ->
      TestModule.include mixinWithDeps
      TestModule::_dependencyFns.length.should.eql 1
      TestModule::_dependencyFns[0].should.eql mixinWithDeps.dependencies






