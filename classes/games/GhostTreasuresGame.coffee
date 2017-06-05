#Created by The Engine Company for Kizzang on 2015.05.29
#Duplicated by Barton Anderson 2015.9.25
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

class exports.GhostTreasuresGame extends SlotGame
	fsSpinsTotal: 0
	fsMxTotal: 0
	fsSecsAdded: 0
	pickSymbols: null
	avgWin: 0

	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@pickSymbols = $json.pickSymbols[0].split ','
		@fsSpinsTotal = parseInt $json.fsSpinsTotal[0]
		@fsMxTotal = parseInt $json.fsMxTotal[0]
		@fsSecsAdded = parseInt $json.fsSecsAdded[0]
		@switchPointsRaw = $json.avgWinDynamicPoints[0]
		@switchPoints = @switchPointsRaw.split ","


	#Create a new session for new players
	createState: ($spinsTotal,$secsTotal)->
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
			analyzerResultGroup.add Analyzer.calculate(session,this.reels,session.fsMxTotal,true,true)

			#Process results
			analyzerResultGroup.process true

		else
			analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

			#Process results
			analyzerResultGroup.process false

		return {
			session: session
			analyzerResultGroup: analyzerResultGroup
		}

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

			#Check triggers, CANNOT pick wild symbol again
			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
			if checkTriggers != null and session.fsSpinsLeft <= 0
				#Shuffle picks
				picks = common.clone @pickSymbols
				common.shuffle picks

				session.fsOn = true
				session.spinsTotal += @fsSpinsTotal
				session.spinsLeft += @fsSpinsTotal
				session.fsSpinsLeft += @fsSpinsTotal
				session.fsSpinsTotal += @fsSpinsTotal
				session.fsMxTotal = @fsMxTotal
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				session.fsWildSymbol = picks[0]
				session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded,picks:picks}
				checkTriggers[0].trigger = 'trigger'

			#Track free spins
			session.fsWinTotal += analyzerResultGroup.pay
			if session.fsSpinsLeft<0
				session.fsWinTotal = 0

		#Base games
		else

			#Check first bonus trigger
			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
			if checkTriggers != null
				#Shuffle picks
				picks = common.clone @pickSymbols
				common.shuffle picks

				session.fsOn = true
				session.spinsTotal += @fsSpinsTotal
				session.spinsLeft += @fsSpinsTotal
				session.fsSpinsLeft += @fsSpinsTotal
				session.fsSpinsTotal += @fsSpinsTotal
				session.fsMxTotal = @fsMxTotal
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				session.fsWildSymbol = picks[0]
				session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded,picks:picks}
				checkTriggers[0].trigger = 'trigger'


	spin: ($state, $request)->

		self = @
		session = new SlotSession this
		if $state
			session.importState $state
			session.fsWildSymbol = $state.fsWildSymbol

		#Switch strips
		json = session.window.slotGame.configuration.stripGroup
		avgWin = parseInt session.winTotal / ( parseInt session.spinsTotal - parseInt session.spinsLeft )

		if session.fsOn and session.fsSpinsLeft>0
			if session.fsWildSymbol == 'P1' then session.window.slotGame.importStripGroup json, 'bonusP1'
			else if session.fsWildSymbol == 'P2' then session.window.slotGame.importStripGroup json, 'bonusP2'
			else if session.fsWildSymbol == 'P3' then session.window.slotGame.importStripGroup json, 'bonusP3'
		else
			if avgWin <= parseInt @switchPoints[0]
  				session.window.slotGame.importStripGroup json, "base5"
			else if avgWin <= parseInt @switchPoints[1]
  				session.window.slotGame.importStripGroup json, "base4"
			else if avgWin <= parseInt @switchPoints[2]
  				session.window.slotGame.importStripGroup json, "base3"
			else if avgWin <= parseInt @switchPoints[3]
  				session.window.slotGame.importStripGroup json, "base2"
			else if avgWin > parseInt @switchPoints[3]
  				session.window.slotGame.importStripGroup json, "base1"
			else
				session.window.slotGame.importStripGroup json, "base3"



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

			break if (self.checkConditionsRoll session, analyzerResultGroup)

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

		if analyzerResultGroup.triggers.length>0 then obj.spin.wins.triggers = analyzerResultGroup.triggers
		if analyzerResultGroup.results.length>0 then obj.spin.wins.results = analyzerResultGroup.results
		if @typeMethod == 'Lines' and analyzerResultGroup.lines.length > 0 then obj.spin.wins.lines = analyzerResultGroup.lineIds

		return obj
