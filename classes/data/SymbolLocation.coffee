#Created by Tony Suriyathep on 2013.12.30

#==================================================================================================#
#Location of a symbol used for return

class exports.SymbolLocation

	symbol:null #String of short
	reel:0 #1 based
	row:0 #1 based

	constructor: (@symbol,@reel,@row)->

	toJSON: -> 
		obj=
			symbol:@symbol
			reel:@reel
			row:@row
		return obj
