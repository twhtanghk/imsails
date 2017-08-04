_ = require 'lodash'
fs = require 'fs'
req = require 'supertest-as-promised'
Promise = require 'bluebird'

describe 'MsgController', ->
  msgs = []

  describe 'create', ->
    it "text msg", ->
      req sails.hooks.http.app
        .post '/api/msg'
        .set 'Authorization', "Bearer #{users[1].token}"
        .send
          to: users[0].jid
          body: "msg from #{users[1].id} to #{users[0].id}"
        .expect 201
        .then ->
          Promise
           .all [
             sails.models.roster.findOne jid: users[0].jid, createdBy: users[1].id
             sails.models.roster.findOne jid: users[1].jid, createdBy: users[0].id
           ]
        .then (rosters) ->
          # check if both roster exists
          if not (rosters[0] and rosters[1])
            throw "rosters #{users[0].jid} or #{users[1].jid} not properly created"
    
    it 'image attachement', ->
      req sails.hooks.http.app
        .post '/api/msg/file'
        .set 'Authorization', "Bearer #{users[1].token}"
        .field 'to', users[0].jid
        .attach 'file', 'test/data/test.png'
        .expect 201
        .then (res) ->
          msgs[1] = res.body
    
    it 'audio attachement', ->
      req sails.hooks.http.app
        .post '/api/msg/file'
        .set 'Authorization', "Bearer #{users[1].token}"
        .field 'to', users[0].jid
        .attach 'file', 'test/data/test.mp3'
        .expect 201
        .then (res) ->
          msgs[2] = res.body
        
  describe 'read', ->
    qs = require 'querystring'
    
    it "list msgs sent", ->
      param = qs.stringify 
        to:   users[0].jid
        type:  'chat'
      req sails.hooks.http.app
        .get "/api/msg?#{param}"
        .set 'Authorization', "Bearer #{users[1].token}"
        .expect 200
    
    it "thumbnail of the image file", ->
      req sails.hooks.http.app
        .get "/api/msg/file/thumb/#{msgs[1].id}"
        .set 'Authorization', "Bearer #{users[1].token}"
        .expect 200
        .parse (res, cb) ->
          new Promise (resolve, reject) ->
            res.pipe fs.createWriteStream '/tmp/test.thumb.png'
              .on 'finish', ->
                cb()
                resolve()
              .on 'error', (err) ->
                cb err
                reject err
        
    it "image file sent", ->
      req sails.hooks.http.app
        .get "/api/msg/file/#{msgs[1].id}"
        .set 'Authorization', "Bearer #{users[1].token}"
        .expect 200
        .parse (res, cb) ->
          new Promise (resolve, reject) ->
            res.pipe fs.createWriteStream '/tmp/test.png'
              .on 'finish', ->
                ret = exec "diff /tmp/test.png test/data/test.png"
                if ret.code != 0
                  throw new Error 'file mismatch'
                cb()
                resolve()
              .on 'error', (err) ->
                cb err
                reject err
          
    it "audio file sent", ->
      req sails.hooks.http.app
        .get "/api/msg/file/#{msgs[2].id}"
        .set 'Authorization', "Bearer #{users[1].token}"
        .expect 200
        .parse (res, cb) ->
          new Promise (resolve, reject) ->
            res.pipe fs.createWriteStream '/tmp/test.mp3'
              .on 'finish', ->
                ret = exec "diff /tmp/test.mp3 test/data/test.mp3"
                if ret.code != 0
                  throw new Error 'file mismatch'
                cb()
                resolve()
              .on 'error', (err) ->
                cb err
                reject err
