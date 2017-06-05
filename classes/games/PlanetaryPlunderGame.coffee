#Created by Tony Suriyathep on 2013.12.30
#Code to analyze and run a Line based slot game

common = require("../../include/common")
SlotGame = require("../data/SlotGame").SlotGame
SlotSession = require("../data/SlotSession").SlotSession
SymbolWindow = require("../data/SymbolWindow").SymbolWindow
SymbolLocation = require("../data/SymbolLocation").SymbolLocation
Analyzer = require("../data/Analyzer").Analyzer
AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup
AnalyzerResult = require("../data/AnalyzerResult").AnalyzerResult
Probability = require("../data/Probability").Probability
ProbabilityGroup = require("../data/ProbabilityGroup").ProbabilityGroup
SymbolGroup = require("../data/SymbolGroup").SymbolGroup

#==================================================================================================#
#Actual game

class exports.PlanetaryPlunderGame extends SlotGame
	fsSpinsTotal: 0
	fsMxTotal: 0
	fsSecsAdded: 0
	avgWin: 0
	symbolCountPerRow = []
	maxBonusGameHits: 0
	currentBonusGameHits: 0
	
	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@fsSpinsTotal = parseInt $json.fsSpinsTotal[0]
		@fsMxTotal = parseInt $json.fsMxTotal[0]
		@fsSecsAdded = parseInt $json.fsSecsAdded[0]
		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]
		
		#Find the wild multipliers
		for i in [0...$json.SymbolCountPerRow[0].row.length]
			symbolCountPerRow[i] = $json.SymbolCountPerRow[0].row[i].$.symbols
	#Create a new session for new players
	createState: ($spinsTotal,$secsTotal)->
		@currentBonusGameHits = parseInt(($spinsTotal - 26) / @fsSpinsTotal);
		json =
			spinsLeft: $spinsTotal
			spinsTotal: $spinsTotal
			secsLeft: $secsTotal
			secsTotal: $secsTotal
			winTotal: 0
			fsOn: false
			fsTrigger: null
			fsSpinsLeft: 0
			fsSpinsTotal: 0
			fsMxTotal: 0
			fsWinTotal: 0
			fsWildSymbol: null
		return json

	#Split spin function to check ez than

	analyzeResultSpin: ($session) ->

		session  = $session

		#Analyze
		analyzerResultGroup = new AnalyzerResultGroup session
		
		if session.fsOn
			results = Analyzer.calculate(session,this.reels,session.fsMxTotal,true,false)
			#if results == null then results = []
			#result = @calculateCustomScatters(session,"S")
			#console.log "Results: " + JSON.stringify(result)
			#results.push result for ind in result
			analyzerResultGroup.add results

			#Process results
			analyzerResultGroup.process true

		else
			results = Analyzer.calculate(session,this.reels,1,true,false)
			#result = @calculateCustomScatters(session,"S")
			
			#console.log "Results: " + JSON.stringify(result)
			#for ind in result
				#if results == null then results = []
				#results.push result 
			analyzerResultGroup.add results
			
			#Process results
			analyzerResultGroup.process false
			
			#if result.length > 0
				#console.log "Result: "  + JSON.stringify(result)
				#console.log "All Results: " + JSON.stringify(analyzerResultGroup.results)
		return {
			session: session
			analyzerResultGroup: analyzerResultGroup
		}

	calculateBonuses:(session, symbol) ->
		
		bonusCount = 0
		for column in [1...session.window.window.length]
			for row in [1...session.window.window[column].length]
				
				if(row > symbolCountPerRow[column-1])
					break
				else if session.window.window[column][row] == symbol
					bonusCount++
		
		if bonusCount >= 3
			#console.log "Bonus Hit"
			return [ {pay: 0} ]
		else 
			return null
	
	calculateCustomScatters:(session, symbol, minKind = 3) ->
		arr = []
		kind = 0
		results = []
		#console.log "calculateScatters"
		for column in [1...session.window.window.length]
			for row in [1...session.window.window[column].length]
				if(row > symbolCountPerRow[column-1])
					break
				else if session.window.window[column][row] == symbol
					#console.log "C:" + column + " R:" + row + " Symbol: " + JSON.stringify(symbol)
					mx = 0
					symbolMatchLocation = new SymbolLocation(session.window.window[column][row],column,row)
					#console.log JSON.stringify(symbolMatchLocation)
					symbolMatch = session.game.symbolGroup.getSymbolById(symbolMatchLocation.symbol)

					#We found a scatter!
					kind++
					arr.push symbolMatchLocation

					#Found a New multiplier - it's additive!
					if symbolMatch.mx > 1
						mx += symbolMatch.mx
						if mx > 10 then mx = 10
				#console.log "C:" + column + " R:" + row + " Symbol: " + JSON.stringify(symbol)
		#Check negatives
		symbol = session.game.symbolGroup.getSymbolById(symbol)
		#symbolMatch = session.game.symbolGroup.getSymbolById(symbolMatchLocation.symbol)
		#console.log "Alright alright alright :" + JSON.stringify(symbol)
		if kind == 0 || kind < minKind
			return results
		if kind > symbol.pays.length  #cap scatter wins to the number of pays that is defined in the xml file
			#console.log kind + " > " + symbol.pays.length
			kind = symbol.pays.length
		
		#No pay at this level
		#if symbol.pays[kind-1]<=0 then continue #there is no payout defined for this number of matches
		if mx == 0
			mx = 1

		#This scatter wins
		result = new AnalyzerResult()
		result.reverse = false
		result.symbol = symbol.id
		result.line = 0
		result.wilds = 0
		result.matches = 1
		result.kind = kind
		result.mx = mx*1
		
		#Scatter pay depends on typeMethod
		if session.game.typeMethod=="Lines"
			# remove mutilpled with betline,betDenom, betCoins
			if symbol.scatter==true
				result.pay = symbol.pays[kind-1]*mx*1
			else
				result.pay = symbol.pays[kind-1]*session.betCoins*session.betDenom*session.betLines*mx*1
		else if session.game.typeMethod=="AllPays"
			result.pay = symbol.pays[kind-1]*$session.betCoins*mx*1

		result.locations = arr
		results.push result
		
		return results
	
	#Free spin handling
	checkFS: ($analyzer, $session)->

		session = $session
		analyzerResultGroup = $analyzer

		if session.fsOn
			session.fsSpinsLeft--
			
			if session.fsSpinsLeft<0
				session.fsOn = false
				session.fsSpinsLeft = 0
				session.fsSpinsTotal = 0
				session.fsMxTotal = 0
				session.fsWildSymbol = null
				session.fsWinTotal = 0
				session.fsTrigger = null
			else
				session.fsTrigger = null
			#Check triggers, CANNOT pick wild symbol again
			checkTriggers = @calculateBonuses(session, "B")#analyzerResultGroup.findSymbolWins 'B',3,3
			if checkTriggers != null and session.fsSpinsLeft <= 0
				session.fsOn = true
				session.spinsTotal += @fsSpinsTotal
				session.spinsLeft += @fsSpinsTotal
				session.fsSpinsLeft += @fsSpinsTotal
				session.fsSpinsTotal += @fsSpinsTotal
				session.fsMxTotal = @fsMxTotal
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded}
				checkTriggers[0].trigger = 'trigger'
				@currentBonusGameHits++

			#Track free spins
			session.fsWinTotal += analyzerResultGroup.pay
			if session.fsSpinsLeft<0
				session.fsWinTotal = 0

		#Base games
		else

			#Check first bonus trigger
			checkTriggers = @calculateBonuses(session, "B")#analyzerResultGroup.findSymbolWins 'B',3,3
			if checkTriggers != null
				session.fsOn = true
				session.spinsTotal += @fsSpinsTotal
				session.spinsLeft += @fsSpinsTotal
				session.fsSpinsLeft += @fsSpinsTotal
				session.fsSpinsTotal += @fsSpinsTotal
				session.fsMxTotal = @fsMxTotal
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded}
				checkTriggers[0].trigger = 'trigger'
				@currentBonusGameHits++


	spin: ($state, $request)->

		self = @
		session = new SlotSession this
		if $state
			session.importState $state
			session.fsWildSymbol = $state.fsWildSymbol

		#Switch strips
		stripJson = this.configuration.stripGroup
		lineJson = this.configuration.lineGroup
		avgWin = parseInt session.winTotal / ( parseInt session.spinsTotal - parseInt session.spinsLeft )


		#console.log JSON.stringify stripJson
		#console.log JSON.stringify lineJson

		if $state.fsOn and $state.fsSpinsLeft>0
			this.importStripGroup stripJson, 'bonus'
			this.importLineGroup lineJson, 'bonus'
		else
			this.importLineGroup lineJson, 'base'
			this.importStripGroup stripJson, 'base'

		session = new SlotSession this
		if $state
			session.importState $state
			
		# Loop untill condition is pass and only do a maximum of 3 retries
		analyze = null
		checkTime = new Date().getTime()

		for i in [0..1000] #1000 Retry Spins!

			#Spin reels, check for cheating
			#if session.spinsLeft == 17 and not session.fsOn then session.window.setReelsByCode 'B,?,B,?,B'
			if not $request or not $request.params.cheat or $request.params.cheat=='?' then spinArr = session.window.spinReels()
			else session.window.setReelsByCode $request.params.cheat

			analyze = self.analyzeResultSpin(session)
			session = analyze.session
			analyzerResultGroup = analyze.analyzerResultGroup

			result = self.checkConditionsRoll session, analyzerResultGroup
			
			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
			if checkTriggers != null
				if (@currentBonusGameHits < @maxBonusGameHits)
					break if (result)
			else
				break if (result)

		#Log a warning if the retry logic took more than 10ms
		operationLimit = 10
		operationTime = new Date().getTime() - checkTime
		if operationTime > operationLimit then console.warn "WARNING: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

		#Handle free spin state
		self.checkFS analyze.analyzerResultGroup, analyze.session

		#Add to player
		session.winTotal += analyzerResultGroup.pay
		session.spinsLeft--

		#Send state
		state = session.exportState()
		state.fsWildSymbol = session.fsWildSymbol

		#Respond!
		obj=
			state: state
			spin:
				window: session.window.export()
				wins:
					wager: session.getTotalWager()
					pay: analyzerResultGroup.pay #Total pay all results
					profit: analyzerResultGroup.profit #Total pay all results
			offsets: spinArr
			currentBonusGameHits: @currentBonusGameHits

		if analyzerResultGroup.triggers.length>0 then obj.spin.wins.triggers = analyzerResultGroup.triggers
		if analyzerResultGroup.results.length>0 then obj.spin.wins.results = analyzerResultGroup.results
		if @typeMethod == 'Lines' and analyzerResultGroup.lines.length > 0 then obj.spin.wins.lines = analyzerResultGroup.lineIds

		return obj
