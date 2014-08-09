# Karma configuration
# Generated on Tue Sep 03 2013 10:12:53 GMT-0600 (MDT)

module.exports = (config) ->
  config.set

    # base path, that will be used to resolve files and exclude
    basePath: './../../'


    # frameworks to use
    frameworks: ['jasmine']


    # list of files / patterns to load in the browser
    files: [
      # vendor
      'components/angular/angular.js',
      'components/underscore/underscore.js',
      'components/angular-linkto/dist/angular-linkto.js',
      'components/angular-lifecycle/dist/angular-lifecycle.js',

      # test helpers
      'components/angular-mocks/angular-mocks.js',
      'node_modules/chai/chai.js',
      'node_modules/sinon/pkg/sinon.js',
      'node_modules/sinon-chai/lib/sinon-chai.js',
      'test/helpers/globals.coffee',

      # app src
      'src/_module.coffee',
      'src/module.coffee',
      'src/**/*.coffee',

      # test specs
      'test/specs/**/*.spec.coffee'
    ]


    # list of files to exclude
    exclude: [

    ]


    # test results reporter to use
    # possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
    reporters: ['progress']


    # web server port
    port: 9876


    # enable / disable colors in the output (reporters and logs)
    colors: true


    # level of logging
    # possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO


    # enable / disable watching file and executing tests whenever any file changes
    autoWatch: true


    # Start these browsers, currently available:
    # - Chrome
    # - ChromeCanary
    # - Firefox
    # - Opera
    # - Safari (only Mac)
    # - PhantomJS
    # - IE (only Windows)
    browsers: ['Chrome']


    # If browser does not capture in given timeout [ms], kill it
    captureTimeout: 60000


    # Continuous Integration mode
    # if true, it capture browsers, run tests and exit
    singleRun: false
