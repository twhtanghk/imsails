Promise = require 'bluebird'
needle = Promise.promisifyAll require 'needle'

module.exports =
  # get token for Resource Owner Password Credentials Grant
  # url: authorization server url to get token 
  # client:
  #   id: registered client id
  #   secret: client secret
  # user:
  #   id: registered user id
  #   secret: user password
  # scope: [ "User", "Mobile"]
  token: (url, client, user, scope) ->
    opts = 
      'Content-Type': 'application/x-www-form-urlencoded'
      username: client.id
      password: client.secret
    data =
      grant_type: 'password'
      username: user.id
      password: user.secret 
      scope: scope.join(' ')
    needle.postAsync url, data, opts
