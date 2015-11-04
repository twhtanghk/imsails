require './device.coffee'

angular.modulue 'starter', ['util.device']
	.config ->
		origin = location.origin
		document.addEventListener 'deviceready', ->
			if (device.platform != 'browser')
				origin = 'file://'
			window.parent.postMessage(location.href, origin)