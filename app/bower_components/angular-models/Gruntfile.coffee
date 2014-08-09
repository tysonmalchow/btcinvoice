matchdep = require 'matchdep'

module.exports = (grunt) ->
  grunt.initConfig

    clean:
      dist: ['dist']

    coffee:
      compile:
        options:
          sourceMap: true
        files:
          'dist/angular-models.js': 'src/**/*.coffee'

    ngmin:
      all:
        src: [ 'dist/angular-models.js' ]
        dest: 'dist/angular-models.js'

    uglify:
      options:
        mangle: true
        compress: true
      app:
        files:
          'dist/angular-models.js': [ 'dist/angular-models.js' ]

  matchdep.filterDev('grunt-*').forEach grunt.loadNpmTasks

  grunt.registerTask 'dist', [ 'clean', 'coffee', 'ngmin', 'uglify' ]
  grunt.registerTask 'default', [ 'dist' ]