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

class exports.FireHouseFrenzyGame extends SlotGame
	fsSpinsTotal: 0
	fsSecsAdded: 0
	avgWin: 0
	maxBonusGameHits: 0
	currentBonusGameHits: 0
	fsPossibleFreeSpins: []
	fsPossibleFreeSpinMultipliers: []
	bonusSpinMax: 0
	firehouseBonusValues: []
	maxFirehousePicks: 0

	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@fsSecsAdded = parseInt $json.fsSecsAdded[0]
		@switchPointsRaw = $json.avgWinDynamicPoints[0]
		@switchPoints = @switchPointsRaw.split ","
		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]
		@fsPossibleFreeSpins = $json.fsSpinsPossibilities[0].split ','
		@fsPossibleFreeSpinMultipliers = $json.fsMultiplierPossibilities[0].split ','
		@bonusSpinMax = $json.maxSingleSpinBonusAmount[0]
		@firehouseBonusValues = $json.firehouseBonusValues[0].split ','
		@maxFirehousePicks = $json.maxFirehousePicks[0]

	#Create a new session for new players
	createState: ($spinsTotal,$secsTotal)->
		largestFreeSpinMulti = 0
		for i in[0...@fsPossibleFreeSpins.length]
			if(largestFreeSpinMulti < parseInt @fsPossibleFreeSpins[i])
				largestFreeSpinMulti = parseInt @fsPossibleFreeSpins[i]

		@currentBonusGameHits = parseInt(($spinsTotal - 26) / largestFreeSpinMulti);
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
			fsMxTotal: 1
			fsWinTotal: 0
			fsWildSymbol: null
		return json

	#Split spin function to check ez than

	analyzeResultSpin: ($session) ->

		session  = $session

		#Analyze
		analyzerResultGroup = new AnalyzerResultGroup session

		if session.fsOn
			analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

			#Process results
			analyzerResultGroup.process true

			if analyzerResultGroup.pay * session.fsMxTotal > @bonusSpinMax
				return null
			else
				#check to see if a firehouse bonus is triggered
				session.firehouseBonus = @checkfirehouseBonus analyzerResultGroup, session
		else
			analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

			#Process results
			analyzerResultGroup.process false

		return {
			session: session
			analyzerResultGroup: analyzerResultGroup
		}

	#firehouse bonus 
	checkfirehouseBonus: ($analyzer, $session)->
		session = $session
		analyzerResultGroup = $analyzer

		checkTriggers = analyzerResultGroup.findSymbolWins 'B2',3,3
		if checkTriggers != null and session.fsSpinsLeft > 0
			#create a firehouse bonus object
			numPicks = parseInt (Math.random() * @maxFirehousePicks)+1

			bonusValues = common.clone @firehouseBonusValues
			common.shuffle bonusValues

			total = 0
			for i in[0...numPicks]
				total += parseInt bonusValues[i]

			obj =
				picks:numPicks
				bonusValues: bonusValues
				total: total

			analyzerResultGroup.pay += total
			return obj
		else
			return null

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
				session.fsWildSymbol = null
				session.fsWinTotal = 0
				session.fsMxTotal = 1
			else
				analyzerResultGroup.pay = analyzerResultGroup.pay * session.fsMxTotal
				session.fsTrigger = null

			#Check triggers, CANNOT pick wild symbol again
			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
			if checkTriggers != null and session.fsSpinsLeft <= 0
				#Shuffle picks
				picks = common.clone @fsPossibleFreeSpins
				common.shuffle picks
				pick = parseInt picks[0]
				
				multipliers = common.clone @fsPossibleFreeSpinMultipliers
				common.shuffle multipliers
				multiplier = parseInt multipliers[0]

				session.fsOn = true
				session.spinsTotal += pick
				session.spinsLeft += pick
				session.fsSpinsLeft += pick
				session.fsSpinsTotal += pick
				session.fsMxTotal = multiplier
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				#session.fsWildSymbol = String pick
				session.fsTrigger = {name:'trigger',spins:pick,secs:@fsSecsAdded}
				checkTriggers[0].trigger = 'trigger'
				@currentBonusGameHits++

			#Track free spins
			session.fsWinTotal += analyzerResultGroup.pay

		#Base games
		else
			session.fsTrigger = null
			session.fsMxTotal = 1
			#Check first bonus trigger
			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
			if checkTriggers != null
				#Shuffle picks
				picks = common.clone @fsPossibleFreeSpins
				common.shuffle picks
				pick = parseInt picks[0]
				
				multipliers = common.clone @fsPossibleFreeSpinMultipliers
				common.shuffle multipliers
				multiplier = parseInt multipliers[0]
				
				session.fsOn = true
				session.spinsTotal += pick
				session.spinsLeft += pick
				session.fsSpinsLeft += pick
				session.fsSpinsTotal += pick
				session.fsMxTotal = multiplier
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				session.fsWildSymbol = null
				session.fsTrigger = {name:'trigger',spins:pick,secs:@fsSecsAdded}
				checkTriggers[0].trigger = 'trigger'
				@currentBonusGameHits++

	spin: ($state, $request)->

		self = @
		session = new SlotSession this
		if $state
			session.importState $state
			#session.fsWildSymbol = parseInt $state.fsWildSymbol

		#Switch strips
		json = session.window.slotGame.configuration.stripGroup
		avgWin = parseInt session.winTotal / ( parseInt session.spinsTotal - parseInt session.spinsLeft )

		if session.fsOn and session.fsSpinsLeft>0
			session.window.slotGame.importStripGroup json, 'bonus'
		else
			session.window.slotGame.importStripGroup json, "base"

		# Loop untill condition is pass and only do a maximum of 3 retries
		analyze = null
		checkTime = new Date().getTime()

		for i in [0..1000] #1000 Retry Spins!

			#Spin reels, check for cheating
			#if session.spinsLeft == 17 and not session.fsOn then session.window.setReelsByCode 'B,?,B,?,B'
			if not $request or not $request.params.cheat or $request.params.cheat=='?' then spinArr = session.window.spinReels()
			else session.window.setReelsByCode $request.params.cheat

			analyze = self.analyzeResultSpin(session)

			if analyze == null
				continue

			session = analyze.session
			analyzerResultGroup = analyze.analyzerResultGroup

			result = self.checkConditionsRoll session, analyzerResultGroup
			
			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
			if checkTriggers != null
				if  @currentBonusGameHits < @maxBonusGameHits && session.spinsLeft > 1
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
		#state.fsWildSymbol = String session.fsWildSymbol
		state.firehouseBonus = session.firehouseBonus

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
