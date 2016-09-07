util = require 'util'
Promise = require 'bluebird'
needle = Promise.promisifyAll require 'needle'

module.exports =
  push: (token, roster, msg) ->
    ready = new Promise (resolve, reject) ->
      if typeof roster.createdBy == 'string'
        sails.models.roster
          .findOne roster.id
          .populateAll()
          .then resolve, reject
      else
        resolve roster

    ready
      .then (roster) ->
        opts = headers:
          Authorization: "Bearer #{token}"
        data =
          users: [roster.createdBy.email]
          data: _.mapValues sails.config.push.data, (value) ->
            _.template(value) {roster: roster, msg: msg}
        needle.postAsync sails.config.push.url, data, opts
          .then (res) ->
            sails.log.debug util.inspect data
            sails.log.info util.inspect res.body
            Promise.resolve res
      .catch (err) ->
        sails.log.error err
        Promise.reject err
