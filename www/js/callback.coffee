require './device.coffee'

angular.module 'starter', ['util.device']
	.config ->
		origin = location.origin
		document.addEventListener 'deviceready', ->
			window.parent.postMessage(location.href, origin)