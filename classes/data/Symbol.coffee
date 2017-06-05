#Created by Tony Suriyathep on 2013.12.30

common = require("../../include/common")


#==================================================================================================#
#One symbol


class exports.Symbol


	id: null #String ID such as A,K,Q
	wild: false
	scatter: false
	mx: 1
	pays: null
	

	constructor: (@id,@pays,@mx=1,@wild=false,@scatter=false)->
	toJSON: -> return @id


	#Import single
	@importFromXml: (json)->
		symbol = new Symbol()
		symbol.id = json.$.id
		symbol.wild = common.toBoolean json.$.wild
		symbol.scatter = common.toBoolean json.$.scatter
		symbol.mx = parseInt json.$.mx

		#Get pays
		symbol.pays = json.$.pays.split(",").map (val)-> 
			return parseInt val		

		return symbol	