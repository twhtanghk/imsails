angular.module 'util.device', []
	.config ->
		document.addEventListener 'deviceready', ->
			platforms =
	        	amazon_fireos:	/cordova-amazon-fireos/
	        	android:		/Android/
	        	ios:			/(iPad)|(iPhone)|(iPod)/
	        	blackberry10:	/(BB10)/
	        	blackberry:		/(PlayBook)|(BlackBerry)/
	        	windows8:		/MSAppHost/
	        	windowsphone:	/Windows Phone/
	        	firefoxos:		/Firefox/
	    	for key, value of platforms
	    		if value.exec navigator.userAgent
	    			device.platform = key
	    			break