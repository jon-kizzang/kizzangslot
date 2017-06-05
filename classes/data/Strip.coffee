#Created by Tony Suriyathep on 2013.12.30

common = require("../../include/common")


#==================================================================================================#
#One strip of symbols


class exports.Strip


	reelId: null #reelId 1 based
	symbolIds: null #Array of Symbol IDs


	constructor: (@reelId,commaDelimSymbolIds)-> 
		if commaDelimSymbolIds then @symbolIds = commaDelimSymbolIds.split(",")


	getRandomStop: ()-> return common.randomInteger(0,@symbolIds.length-1)
	getRandomSymbol: ()-> return @symbolIds[@getRandomStop()]
	getSymbol: (stop)-> return @symbolIds[common.rotateNumber(stop,@symbolIds.length-1)]
	getLength: ()-> return @symbolIds.length


	#Get a row of symbols
	getSymbols: (stop,rowCount)->
		ret = []
		ret.push @getSymbol(i) for i in [stop..(stop+rowCount-1)]
		return ret


	#Find a list of symbols that match the strip, -1 for no match
	findStopBySymbol: (symbolId)->
		for i in [0..@symbolIds.length-1]
			if @getSymbol(i)==symbolId then return i
		return -1


	#Find a list of symbols that match the strip, -1 for no match
	findStopBySymbols: (commaDelimSymbolIds)->
		finds = commaDelimSymbolIds.split(",")
		findLength = finds.length
		for i in [0..@symbolIds.length-1]
			ok = true
			for j in [0..findLength-1]
				if @getSymbol(i+j)!=finds[j]  
					ok = false
					break
			if ok == true then return i
		return -1


	#Import single 
	@importFromXml: (reelId,json)->
		strip = new Strip(reelId)
		strip.symbolIds = json.$.symbols.split(",")
		return strip




