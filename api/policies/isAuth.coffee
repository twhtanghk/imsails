_ = require 'lodash'
passport = require 'passport'
bearer = require 'passport-http-bearer'
oauth2 = require 'oauth2_client'

passport.use 'bearer', new bearer.Strategy {} , (token, done) ->
  oauth2
    .verify sails.config.oauth2.verifyUrl, sails.config.oauth2.scope, token
    .then (info) ->
      sails.models.user
        .findOrCreate _.pick(info.user, 'email')
        .populateAll()
    .then (user) ->
      done null, user
    .catch (err) ->
      done null, false, message: err

module.exports = (req, res, next) ->
  middleware = passport.authenticate('bearer', { session: false } )
  middleware req, res, ->
    next()
