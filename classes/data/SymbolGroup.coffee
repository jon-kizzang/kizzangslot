#Created by Tony Suriyathep on 2013.12.30



common = require("../../include/common")

Symbol = require("./Symbol").Symbol



#==================================================================================================#

#Group of symbols



class exports.SymbolGroup



	id: null #Group such as base, feature

	symbols: null #Array of Symbol

	symbolMap: {} #Map of Symbols, split by ID



	constructor: (@id,@symbols)->

	getRandomSymbol: ()-> return @symbols[common.randomInteger(0,@symbols.length-1)]

	getRandomSymbolId: ()-> return @getRandomSymbol().id

	

	getSymbolById: (id)->

		if !@symbolMap[id.toString()] then return null

		return @symbolMap[id.toString()]



	#Import single lineGroup

	@importFromXml: (json)->
		
		symbolGroup = new SymbolGroup()

		symbolGroup.id = json.$.id



		#Import lines

		symbolGroup.symbols = []

		for symbol in json.symbol

			newSymbol = Symbol.importFromXml symbol

			symbolGroup.symbols.push newSymbol

			symbolGroup.symbolMap[newSymbol.id.toString()] = newSymbol



		return symbolGroup

	

