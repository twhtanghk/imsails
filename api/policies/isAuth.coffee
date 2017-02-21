_ = require 'lodash'
passport = require 'passport'
bearer = require 'passport-http-bearer'
oauth2 = require 'oauth2_client'

passport.use 'bearer', new bearer.Strategy {} , (token, done) ->
  oauth2
    .verify sails.config.oauth2.verifyUrl, sails.config.oauth2.scope, token
    .then (info) ->
      sails.models.user
        .findOrCreate _.pick(info.user, 'username', 'email')
        .populateAll()
    .then (user) ->
      user.token = token
      done null, user
    .catch (err) ->
      done null, false, message: err

module.exports = (req, res, next) ->
  if req.isSocket
    req = _.extend req, _.pick(require('http').IncomingMessage.prototype, 'login', 'logIn', 'logout', 'logOut', 'isAuthenticated', 'isUnauthenticated')

  middleware = passport.authenticate('bearer', { session: false } )
  middleware req, res, ->
    if req.isSocket
      req.socket.user = req.user
    next()
