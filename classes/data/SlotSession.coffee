#Created by Tony Suriyathep on 2013.12.30

common = require("../../include/common")
SymbolWindow = require("./SymbolWindow").SymbolWindow


#==================================================================================================#
#Sort and sum results


class exports.SlotSession
	mode: 'base'
	
	#Player
	game: null
	betLines: 0
	betCoins: 0
	betDenom: 0
	window: null
		
	#State
	spinsLeft: 0
	spinsTotal: 0
	secsLeft: 0
	secsTotal: 0
	winTotal: 0
	fsOn: false
	fsTrigger: null #Name of the bonus that was trigger "Trigger" or "Retrigger"
	fsSpinsLeft: 0
	fsSpinsTotal: 0
	fsMxTotal: 0
	fsWinTotal: 0
	
	
	constructor: (@game)->
		@betLines = @game.lines
		@betDenom = @game.denomDefault
		@betCoins = @game.coinDefault
		@window = new SymbolWindow(@game)
	
	
	exportState: ->
		json = 
			spinsLeft: @spinsLeft
			spinsTotal: @spinsTotal
			secsLeft: @secsLeft
			secsTotal: @secsTotal
			winTotal: @winTotal
			fsOn: @fsOn
			fsTrigger: @fsTrigger
			fsSpinsLeft: @fsSpinsLeft
			fsSpinsTotal: @fsSpinsTotal
			fsMxTotal: @fsMxTotal
			fsWinTotal: @fsWinTotal
		return json
			
			
	importState: ($source)->
		@spinsLeft = parseInt $source.spinsLeft
		@spinsTotal = parseInt $source.spinsTotal
		@secsLeft = parseInt $source.secsLeft
		@secsTotal = parseInt $source.secsTotal
		@winTotal = parseInt $source.winTotal
		@fsOn = $source.fsOn
		@fsTrigger = $source.fsTrigger
		@fsSpinsLeft = parseInt $source.fsSpinsLeft
		@fsSpinsTotal = parseInt $source.fsSpinsTotal
		@fsMxTotal = parseInt $source.fsMxTotal
		@fsWinTotal = parseInt $source.fsWinTotal
				
									
	#Total wager for this player
	getTotalWager: ->
		if @game.typeMethod == 'AllPays' then return @betCoins*@betDenom
		else if @game.typeMethod == 'Lines' then return @betCoins*@betDenom*@betLines
		return -1
		
		