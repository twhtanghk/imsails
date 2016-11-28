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

        connect: (url) ->
          url = url.replace 'file://', ''
          @media = $cordovaMedia.newMedia url
          @media
            .getDuration()
            .then (duration) ->
              buffer: 
                duration: duration

        start: (url) ->
          url = url.replace 'file://', ''
          @media = $cordovaMedia.newMedia url
          @media.play()

        stop: ->
          @media.stop()
          @media.release()

      if $cordovaDevice.getPlatform() != 'browser'
        $delegate.player = Player.instance()
      return $delegate
