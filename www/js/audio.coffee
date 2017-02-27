require 'util.audio'
Promise = require 'bluebird'
numeral = require 'numeral'
EventEmitter = require('events').EventEmitter

angular

  .module 'starter.audio', ['util.audio', 'ngCordova']

  .config ($provide) ->
    $provide.decorator 'audioService', ($delegate, $cordovaDevice, $cordovaMedia) ->
      class Player extends EventEmitter
        _instance = null

        @instance = ->
          _instance ?= new Player()

        @url = (url) ->
          pattern = new RegExp '^file://(.*)'
          if device.platform == 'iOS' and pattern.test url
            res = url.match pattern
            return res[1]
          else
            return url
      
        connect: (url) ->
          url = Player.url url
          @media = $cordovaMedia.newMedia url
          @media
            .getDuration()
            .then (duration) ->
              buffer: 
                duration: duration

        start: (url) ->
          url = Player.url url
          @media = $cordovaMedia.newMedia url
          @media.play()

        stop: ->
          @media.stop()
          @media.release()

      
      document.addEventListener 'deviceready', ->
        if $cordovaDevice.getPlatform() != 'browser'
          $delegate.player = Player.instance()

      return $delegate

  .run ($rootScope, audioService) ->
    document.addEventListener 'deviceready', ->
      $rootScope.audioService = audioService
