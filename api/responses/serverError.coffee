###
	data = 
		code:	400
		msg:	"not authorized to post #{url}"
		fields:
			name:	"duplicate name #{name}"
###
module.exports = (data, options = {}) ->
	req = @req
	res = @res
	sails = req._sails

	res.status(500)

	if data
		sails.log.error('Sending 500 ("Server Error") response: \n',data)
	else
		sails.log.error('Sending empty 500 ("Server Error") response');

	if req.wantsJSON
		return res.jsonx(data)

	if typeof options == 'string'
		options = view: options

	if (options.view)
    	return res.view(options.view, { data: data })
	else
		return res.view '500', { data: data }, (err, html) ->
			if err
				if err.code == 'E_VIEW_FAILED'
					sails.log.verbose('res.serverError() :: Could not locate view for error page (sending JSON instead).  Details: ',err)
				else
	        		sails.log.warn('res.serverError() :: When attempting to render error page view, an error occured (sending JSON instead).  Details: ', err)
	      		return res.jsonx(data);
	    
	    	return res.send(html)