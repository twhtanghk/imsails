assert = require 'assert'

[
  'ADMIN'
].map (name) ->
  assert name of process.env, "process.env.#{name} not yet defined"

# check if authenticated user is admin or the same user to be updated
module.exports = (req, res, next) ->
  if req.user.email in process.env.ADMIN.split ','
    return next()

  res.forbidden()
