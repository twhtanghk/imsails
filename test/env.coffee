agent = require 'https-proxy-agent'

module.exports =
	timeout: 400000
	client: 
		id:		'cP;zbWa@cp4m.iXvSSDr51asIx7as60Sg3?SpcZN'
		secret: 'TyHvbDwg_D?5aIODJ2;hrH5?pP5TqatIHshope?DD9OGL8Hg4CypT?V_1!Oi1ZQGlnsu?wU80uUmSky;c8fm-qajTXFTh:ewcf7d-COyr6Gt=NwJVMR=I6MDcYxDH2DI'
	user:
		id:		'twhtang'
		secret:	'tom2130'
	http:
		opts:
			timeout: 	10000
			agent:		new agent('http://proxy1.scig.gov.hk:8080')	