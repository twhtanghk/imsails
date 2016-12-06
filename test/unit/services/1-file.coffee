env = require '../../env.coffee'
require 'shelljs/global'
fs = require 'fs'
path = require 'path'

describe 'message', ->
  @timeout env.timeout
  
  msg = null
        
  before ->
    sails.models.msg
      .findOne file: like: '%png'
      .then (img) ->
        msg = img
        
  describe 'file', ->
    it 'content', ->
      sails.services.file.content sails.models.msg, msg.id 
        .then (file) ->
          if file.prop.filename != msg.file
            return Promise.reject new Error 'name mismatch'
          file.stream.pipe fs.createWriteStream "/tmp/test.png"
            .on 'finish', ->
              ret = exec "diff /tmp/test.png test/data/test.png"
              if ret.code != 0
                reject new Error 'file mismatch'
              Promise.resolve()
            .on 'error', Promise.reject
        
    it 'thumb', ->
      sails.services.file.thumb sails.models.msg, msg.id 
        .then (file) ->
          if file.prop.filename != sails.services.file.thumbName(msg.file)
            return Promise.reject new Error 'name mismatch'
          file.stream.pipe fs.createWriteStream "/tmp/test.thumb.png"
            .on 'finish', Promise.resolve
            .on 'error', Promise.reject
