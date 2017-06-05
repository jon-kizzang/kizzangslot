#Created by Tony Suriyathep on 2013.12.30
#Client to server communication

common = require '../include/common'
ProtocolCrypto = require('./ProtocolCrypto').ProtocolCrypto



#==================================================================================================#
class exports.ProtocolServer



#--------------------------------------------------------------------------------------------------#
	ok: 0
	msg: null
	request: null
	response: null
#--------------------------------------------------------------------------------------------------#



#--------------------------------------------------------------------------------------------------#
	constructor: (@ok,@msg=null,@request=null,@response=null) ->
		#Check if echo is off
		if @request and @request.echo==0 then delete @request.echo
#--------------------------------------------------------------------------------------------------#



#--------------------------------------------------------------------------------------------------#
	out: ->
		json = {}
		json.ok = @ok
		if @msg then json.msg = @msg
		if @request then json.request = @request
		if @response then json.response = @response  
		str = JSON.stringify json 
		return ProtocolCrypto.encrypt(str)
#--------------------------------------------------------------------------------------------------#