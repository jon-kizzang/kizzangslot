#Created by The Engine Company for Kizzang on 2015.11.23
#Code to analyze and run a Line based slot game

common = require("../../include/common")
SlotGame = require("../data/SlotGame").SlotGame
SlotSession = require("../data/SlotSession").SlotSession
SymbolWindow = require("../data/SymbolWindow").SymbolWindow
Analyzer = require("../data/Analyzer").Analyzer
AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup


#==================================================================================================#
#Actual game

class exports.MoneyBoothGame extends SlotGame
	BONUS_1_SYM: 'B1'
	BONUS_2_SYM: 'B2'
	BONUS_3_SYM: 'B3'
	maxBonusGameHits: 0
	bonusValues: null
	bonusMultMin: 0
	bonusMiltMax: 5
	bonusSecsAdded: 0
	
	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@bonusSecsAdded = parseInt $json.bonusSecsAdded[0]
		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]
		@bonusValues = $json.bonusValues[0].split ','
		for i in [0 .. @bonusValues.length-1]
			@bonusValues[i] = parseInt @bonusValues[i]

		@bonusMultMin = parseInt $json.bonusMultMin[0]
		@bonusMultMax = parseInt $json.bonusMultMax[0]
		
	#Create a new session for new players
	createState: ($spinsTotal,$secsTotal)->
		json =
			spinsLeft: $spinsTotal
			spinsTotal: $spinsTotal
			secsLeft: $secsTotal
			secsTotal: $secsTotal
			winTotal: 0
			fsMxTotal: 0
		return json

	calculateBonuses:(session, symbol) ->
		bonusCount = 0
		for i in [1...session.window.window.length]
			sym = session.window.window[i][1]
			if (sym == symbol)
				bonusCount++
		
		if bonusCount == 0
			return null
		return {
				pay: 0
				numBonuses: bonusCount
		}

	adjustSymbolsBecauseOfBonusSymbol:(session) ->
		for i in [1...session.window.window.length]
			for j in [1...session.window.window[i].length]	
				sym = session.window.window[i][j]
				if (sym == @BONUS_1_SYM)
					if(j+1 < session.window.window[i].length)
						session.window.window[i][j+1] = "B2"
					if(j+2 < session.window.window[i].length)
						session.window.window[i][j+2] = "B3"
					
	# Split spin function to check ez than
	analyzeResultSpin: (session, checkTriggers) ->
		#Do some reel magic to make sure things are rendered and counted properly
		
		#Analyze
		analyzerResultGroup = new AnalyzerResultGroup session
		analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

		#Process results
		analyzerResultGroup.process false

		#Check trigger
		if checkTriggers != null && checkTriggers.numBonuses > 2
			#There is a bonus game!
			#Shuffle the bonus values array
			@bonusValues = common.shuffle(@bonusValues)
			
			#Determine the multiplier
			multiplier = Math.floor(Math.random() * (@bonusMultMax - @bonusMultMin + 1)) + @bonusMultMin
			
			#Determine the total score
			total = 0
			for i in [0...checkTriggers.numBonuses]
				total += @bonusValues[i]
			
			total *= multiplier
			
			#Construct data to return!
			session.bonusInfo = {
				numberOfPicks: checkTriggers.numBonuses,
				bonusValues: @bonusValues.slice(),
				multiplier: multiplier,
				total: total,
				secs: @bonusSecsAdded
			}
			
			#The scatter win receives the wins of the picks
			checkTriggers.trigger = 'trigger'
			checkTriggers.pay += total

			#Process results
			analyzerResultGroup.pay += total

		#No bonus!
		else
			session.bonusInfo = null

		return {
			session: session
			analyzerResultGroup: analyzerResultGroup
		}
	shouldAllowThisBonus: (session, bonusGamePickValues, currentBonusGameHits) ->
		currentNumOfPicks = session.bonusInfo.numberOfPicks
		hasAlreadyGottenSinglePick = false
		for j in [0...bonusGamePickValues.length]
			if bonusGamePickValues[j] == currentNumOfPicks
				return false
		return true
		
	spin: ($state, $request)->
		
		self = @
		session = new SlotSession this
		if $state
			session.importState $state
		spinArr = null

		# Loop till condition is pass
		checkTime = new Date().getTime()

		for i in [0...1000] #1000 Retry Spins!
			#Spin reels, check for cheating
			#if session.spinsLeft == 17 and not session.fsOn then session.window.setReelsByCode 'B,?,B,?,B'
			if not $request or not $request.params.cheat or $request.params.cheat=='?' then spinArr = session.window.spinReels()
			else session.window.setReelsByCode $request.params.cheat

			#@adjustSymbolsBecauseOfBonusSymbol session
			checkTriggers = @calculateBonuses session, @BONUS_1_SYM

			analyze = self.analyzeResultSpin(session, checkTriggers)
			session = analyze.session
			analyzerResultGroup = analyze.analyzerResultGroup

			result = self.checkConditionsRoll session, analyzerResultGroup

			if checkTriggers == null
				if result then break
			else
				
				if checkTriggers.numBonuses < 3
					continue
				else
					if  session.fsMxTotal < @maxBonusGameHits && session.spinsLeft > 1
						if (result) then	break

		#Only add time if there is a pick bonus
		if session.bonusInfo
			#console.log "Spin Bonus: " + JSON.stringify(session.bonusInfo)# + " ||| currentBonusGameHits: " + @currentBonusGameHits + " ||| maxbonusGameHits: " + @maxBonusGameHits
			session.fsMxTotal++
			session.secsTotal += @bonusSecsAdded
			session.secsLeft += @bonusSecsAdded

		#Log a warning if the retry logic took more than 10ms
		operationLimit = 10
		operationTime = new Date().getTime() - checkTime
		if operationTime > operationLimit then console.warn "WARNING -MoneyBoothGame: Respin took more than " + operationLimit + "\nms. Operation took " + operationTime + "ms over " + i + " spins"

		#Add to player
		session.winTotal += analyzerResultGroup.pay
		session.spinsLeft--

		#Send state
		state = session.exportState()
		if(session.bonusInfo)
			state.bonusInfo = session.bonusInfo
		
		delete state.fsOn
		delete state.fsSpinsLeft
		delete state.fsSpinsTotal
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

		if analyzerResultGroup.triggers.length>0 then obj.spin.wins.triggers = analyzerResultGroup.triggers
		if analyzerResultGroup.results.length>0 then obj.spin.wins.results = analyzerResultGroup.results
		if @typeMethod == 'Lines' and analyzerResultGroup.lines.length > 0 then obj.spin.wins.lines = analyzerResultGroup.lineIds

		return obj
