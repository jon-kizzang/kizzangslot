#Created by Tony Suriyathep on 2013.12.30
#Code to analyze and run a Line based slot game

common = require("../../include/common")
SlotGame = require("../data/SlotGame").SlotGame
SlotSession = require("../data/SlotSession").SlotSession
SymbolWindow = require("../data/SymbolWindow").SymbolWindow
Analyzer = require("../data/Analyzer").Analyzer
AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup
Probability = require("../data/Probability").Probability
ProbabilityGroup = require("../data/ProbabilityGroup").ProbabilityGroup


#==================================================================================================#
#Actual game

class exports.PuppyCashGame extends SlotGame
	maxBonusGameHits: 0
	currentBonusGameHits: 0
	pickBubbles: null
	pickSecsAdded: 0
	numExtraPicks: 0
	
	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@pickBubbles = $json.pickBubbles[0].split ','
		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]
		@pickSecsAdded = parseInt $json.pickSecsAdded[0]
		
	#Create a new session for new players
	createState: ($spinsTotal,$secsTotal)->
		@currentBonusGameHits = 0
		@numExtraPicks = 0
		
		json =
			spinsLeft: $spinsTotal
			spinsTotal: $spinsTotal
			secsLeft: $secsTotal
			secsTotal: $secsTotal
			winTotal: 0
			pickBonus: null
		return json

	# Split spin function to check ez than
	analyzeResultSpin: (session) ->
		#Analyze
		analyzerResultGroup = new AnalyzerResultGroup session
		analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

		#Process results
		analyzerResultGroup.process false

		#Check trigger
		checkMainBonusTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
		
		session.MainBonusInfo = null
		session.MultiplierBonusInfo = null
		
		if checkMainBonusTriggers != null
			#Main Bonus
			session.MainBonusInfo = @startMainBonusGame()
			#Process results
			analyzerResultGroup.pay += session.MainBonusInfo.win
		else
			if @checkForMultiplierTrigger(analyzerResultGroup)
				#Multiplier Bonus
				session.MultiplierBonusInfo = @startMultiplierBonusGame()
				analyzerResultGroup.pay *= session.MultiplierBonusInfo.randomMultiplier

		return {
			session: session
			analyzerResultGroup: analyzerResultGroup
		}

	startMainBonusGame: ()->
		#Setup the bubble picks that the user will choose
		@numExtraPicks = 0
		
		bubbles = @shuffleBubbles()
		while(bubbles[0].type != 0)
			@numExtraPicks = 0
			bubbles = @shuffleBubbles()
		total = 0
		totalMultiplier = 0
		
		for j in [0...3+@numExtraPicks]
			if bubbles[j].type == 0
				total += parseInt(bubbles[j].value)
			else if bubbles[j].type == 1
				totalMultiplier += parseInt(bubbles[j].value.charAt(0))
		
		if(totalMultiplier == 0)
			totalMultiplier = 1;
		
		total = total*totalMultiplier
		MainBonusInfo =
			numberOfPicks: 3+@numExtraPicks
			values: bubbles
			secs: @pickSecsAdded
			win: total
		
		#console.log "Bubbles: " + JSON.stringify(bubbles)
		return MainBonusInfo

	shuffleBubbles: ()->
		newBubbles = []
		@pickBubbles = common.shuffle @pickBubbles
		for i in [0...@pickBubbles.length-1]
			newBubbles[i] = @createBubblePick(@pickBubbles[i], i)
		return newBubbles

	createBubblePick: (pick, currentPick)->
		type = 0
		value = pick
		if pick == "+1 Pick"
			type = 2
			if(currentPick < 3+@numExtraPicks)
				@numExtraPicks++
		else if pick == "2x" || pick == "3x" || pick == "4x" || pick == "5x"
			type = 1
		
		newPick =
			type: type
			value: pick
		
		#console.log "Pick: " + JSON.stringify(pick) + "\n"
		#console.log "New Pick: " + JSON.stringify(newPick) + "\n"
		return newPick

	checkForMultiplierTrigger: (analyzerResultGroup) ->
		results = analyzerResultGroup.results
		
		for i in [0...results.length]
			result = results[i]
			if result.symbol == "P4B" || result.symbol == "P3B" || result.symbol == "P2B" || result.symbol == "P1B"
				return true;
		
		return false

	startMultiplierBonusGame: ()->
		MultiplierBonusInfo = 
			randomMultiplier: parseInt(@probabilityGroup.run('pickMultipliers'))
			secs: @pickSecsAdded
		return MultiplierBonusInfo

	spin: ($state, $request)->
		
		self = @
		session = new SlotSession this
		if $state then	session.importState $state
		#console.log session

		spinArr = null

		# Loop till condition is pass
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
			
		#Only add time if there is a pick bonus
		if session.MainBonusInfo != null
			#console.log "Main Bonus Info: " + JSON.stringify(session.MainBonusInfo)
			@currentBonusGameHits++
			session.secsTotal += @pickSecsAdded
			session.secsLeft += @pickSecsAdded

		#Log a warning if the retry logic took more than 10ms
		operationLimit = 10
		operationTime = new Date().getTime() - checkTime
		if operationTime > operationLimit then console.warn "WARNING -PuppyCashGame: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

		#Add to player
		session.winTotal += analyzerResultGroup.pay
		session.spinsLeft--

		#Send state
		state = session.exportState()
		state.MainBonusInfo = session.MainBonusInfo
		state.MultiplierBonusInfo = session.MultiplierBonusInfo
			
		delete state.fsOn
		delete state.fsSpinsLeft
		delete state.fsSpinsTotal
		delete state.fsMxTotal
		delete state.fsWinTotal

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
