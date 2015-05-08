fs = require 'fs'
_ = require 'underscore'
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
	model = sails.models
	
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
			model.users.findOrCreate user, (err, user) ->
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
	a = passport.authenticate('bearer', { session: false })
	a(req, res, next)