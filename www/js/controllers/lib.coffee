reader = new FileReader()

module.exports =
	readFile: (files) ->
		new Promise (fulfill, reject) ->
			reader.onload = (event) =>
				fulfill event.target.result 
			reader.readAsDataURL(files[0])