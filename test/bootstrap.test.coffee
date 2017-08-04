fs = require 'fs'
Promise = require 'bluebird'
oauth2 = require 'oauth2_client'
Sails = Promise.promisifyAll require 'sails'
assert = require 'assert'
_ = require 'lodash'

[
  'USER_ID'
  'USER_SECRET'
  'CLIENT_ID'
  'CLIENT_SECRET'
  'TOKENURL'
  'VERIFYURL'
  'OAUTH2_SCOPE'
].map (name) ->
  assert name of process.env, "process.env.#{name} not yet defined"

before ->
  users =
    id: process.env.USER_ID.split ','
    secret: process.env.USER_SECRET.split ','
  users = _.map users.id, (id, index) ->
    id: id
    secret: users.secret[index]
  client =
    id: process.env.CLIENT_ID
    secret: process.env.CLIENT_SECRET
  scope = process.env.OAUTH2_SCOPE.split ' '
  Promise
    .map users, (user) ->
      oauth2
        .token process.env.TOKENURL, client, user, scope
        .then (token) ->
          _.extend user, token: token
          oauth2.verify process.env.VERIFYURL, scope, token
        .then (curr) ->
          _.extend user, curr.user
    .then (users) ->
      global.users = users
    .then ->
      Sails.liftAsync JSON.parse fs.readFileSync './.sailsrc'
		
after ->
  Sails.lowerAsync()
