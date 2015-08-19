http = require 'needle'
fs = require 'fs'

dir = '/etc/ssl/certs'
files = fs.readdirSync(dir).filter (file) -> /.*\.pem/i.test(file)
files = files.map (file) -> "#{dir}/#{file}"
ca = files.map (file) -> fs.readFileSync file

options = 
	timeout:	sails.config.promise.timeout
	ca:			ca
		
module.exports =
	get: (token, url) ->
		new Promise (fulfill, reject) ->
			opts = _.extend options,
				headers:
					Authorization:	"Bearer #{token}"
			http.get url, opts, (err, res) ->
				if err
					return reject err
				fulfill res
				
	post: (token, url, data) ->
		new Promise (fulfill, reject) ->
			opts = _.extend options,
				headers:
					Authorization:	"Bearer #{token}"
			http.post url, data, opts, (err, res) ->
				if err
					return reject err
				fulfill res
					
	push: (token, roster, msg) ->
		param =
			roster: roster
			msg:	msg
		data =
			url: _.template "/chat/<%=msg.type%>/<%=msg.createdBy%>", param
			title: _.template "<%=roster.name()%>", param
			message: _.template "<%=roster.newmsg%> message(s)", param
		@post token, sails.config.push.url, 
			users:	[roster.createdBy.email]
			data:	data
			
	gcmPush: (users, data) ->
		new Promise (fulfill, reject) ->
			opts = _.extend options,
				headers:
					Authorization: 	"key=#{sails.config.push.gcm.apikey}"
					'Content-Type': 'application/json'
				json:		true
			devices = []
			_.each users, (user) ->
				_.each user.devices, (device) ->
					devices.push device.regid 
			defaultMsg =
				title:		'Instant Messaging'
				message:	' '
			data =
				registration_ids:	_.uniq(devices)
				data:				_.extend defaultMsg, data
			http.post sails.config.push.gcm.url, data, opts, (err, res) =>
				if err
					return reject(err)
				fulfill(res.body)