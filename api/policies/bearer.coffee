# check if oauth2 bearer is available
fs = require 'fs'
_ = require 'lodash'
http = require 'needle'
passport = require 'passport'
bearer = require 'passport-http-bearer'
Promise = require 'promise'

dir = '/etc/ssl/certs'
files = fs.readdirSync(dir).filter (file) -> /.*\.pem/i.test(file)
files = files.map (file) -> "#{dir}/#{file}"
ca = files.map (file) -> fs.readFileSync file

verifyToken = (token) ->
	opts = 
		timeout:	sails.config.promise.timeout
		ca:			ca
		headers:
			Authorization:	"Bearer #{token}"
	
	oauth2 = sails.config.oauth2
	
	return new Promise (fulfill, reject) ->
		http.get oauth2.verifyURL, opts, (err, res, body) ->
			if err or res.statusCode != 200
				return reject('Unauthorized access')
					
			# check required scope authorized or not
			scope = body.scope.split(' ')
			result = _.intersection scope, oauth2.scope
			if result.length != oauth2.scope.length
				return reject('Unauthorized access to #{oauth2.scope}')
				
			# create user
			# otherwise check if user registered before (defined in model.User or not)
			user = _.pick body.user, 'url', 'username', 'email'
			sails.models.user.findOrCreate user, (err, user) ->
				if err
					return reject(err)
				fulfill(user)

passport.use 'bearer', new bearer.Strategy {}, (token, done) ->
	fulfill = (user) ->
		user.token = token
		done(null, user)
	reject = (err) ->
		done(null, false, message: err)
	verifyToken(token).then fulfill, reject
	
module.exports = (req, res, next) ->
	if req.isSocket
		req = _.extend req, _.pick(require('http').IncomingMessage.prototype, 'login', 'logIn', 'logout', 'logOut', 'isAuthenticated', 'isUnauthenticated')
	middleware = passport.authenticate('bearer', { session: false })
	middleware(req, res, next)