#Created by Tony Suriyathep on 2013.12.30
#Client to server communication

common = require '../include/common'
ProtocolCrypto = require('./ProtocolCrypto').ProtocolCrypto



#==================================================================================================#
class exports.ProtocolClient



#--------------------------------------------------------------------------------------------------#
	cmd: null
	echo: 1
	params: null
#--------------------------------------------------------------------------------------------------#



#--------------------------------------------------------------------------------------------------#
	constructor: (@cmd,@echo=1,@params=null) -> return
#--------------------------------------------------------------------------------------------------#



#--------------------------------------------------------------------------------------------------#
	out: ->
		json = {}
		json.cmd = @cmd
		json.echo = @echo
		json.params = @params
		return ProtocolCrypto.encrypt JSON.stringify json
#--------------------------------------------------------------------------------------------------#



#--------------------------------------------------------------------------------------------------#
	@import: ($alreadyDecrypted) ->
		n = JSON.parse $alreadyDecrypted 
		if not n.cmd then return null
		if not n.echo then n.echo=0
		return new ProtocolClient(n.cmd,n.echo,n.params)
#--------------------------------------------------------------------------------------------------#