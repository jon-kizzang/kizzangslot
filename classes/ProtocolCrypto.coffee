#Created by Tony Suriyathep on 2013.12.30
#Encrypt strings

crypto = require 'crypto'
common = require '../include/common'



#==================================================================================================#
class exports.ProtocolCrypto



#--------------------------------------------------------------------------------------------------#
	@on: true #If there is no encryption then set to false
	@method: 'des-ecb'
	@format: 'base64' #hex or base64
	@key: '12345678'
#--------------------------------------------------------------------------------------------------#



#--------------------------------------------------------------------------------------------------#
	@encrypt: ($txt) ->
		if not @on then return $txt
		cipher = crypto.createCipheriv @method, @key, ''
		crypted = cipher.update $txt, 'utf8', @format
		crypted += cipher.final @format
		return crypted
#--------------------------------------------------------------------------------------------------#



#--------------------------------------------------------------------------------------------------#
	@decrypt: ($encrypted) ->
		if not @on then return $encrypted
		decipher = crypto.createDecipheriv @method, @key, ''
		decrypted = decipher.update $encrypted, @format, 'utf8'
		decrypted += decipher.final 'utf8'
		return decrypted
#--------------------------------------------------------------------------------------------------#



