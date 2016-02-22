module.exports =
	
	tableName:	'fs.files'
	
	schema:		true
	
	autoPK:		true
	
	attributes:
		filename:
			type:		'string'
			required:	true
			
		contentType:
			type:		'string'
			
		length:
			type:		'integer'
			
		uploadDate:
			type:		'datetime'
			
		metadata:
			type:		'json'
			
		md5:
			type:		'string'