#Created by Tony Suriyathep on 2013.12.30

#==================================================================================================#
#One result

class exports.AnalyzerResult

	line: 0
	symbol: null
	kind: 0 #How many symbols left to right only
	matches: 0 #Overlapping wins useful for AllPays
	wilds: 0 #Count of wilds in this win
	mx: 1 #Total multiplier
	pay: 0 #How much it paid
	locations: null #SymbolLocations of all the symbols
	reverse: false #For TwoWay pay
	trigger: null #Triggers will show up first

	toJSON: -> 
		obj=
			symbol: @symbol
			kind: @kind #How many symbols left to right only
			matches: @matches #Overlapping wins useful for AllPays
			wilds: @wilds #Count of wilds in this win
			mx: @mx #Total multiplier
			pay: @pay #How much it paid
			locations: @locations #SymbolLocations of all the symbols
		
		#Unlikely its a reverse result
		if @reverse then obj.reverse = true

		#Triggers will show up first
		if @trigger!=null then obj.trigger = @trigger 

		#Line null probably means scatter
		if @line>0 then obj.line = @line

		return obj

