common = require("../../include/common")
SlotGame = require("../data/SlotGame").SlotGame
SlotSession = require("../data/SlotSession").SlotSession
SymbolWindow = require("../data/SymbolWindow").SymbolWindow
Analyzer = require("../data/Analyzer").Analyzer
AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup


class exports.AsteroidsGame extends SlotGame
	maxBonusGameHits: 3
	bonusLargeAsteroidMin: 4
	bonusLargeAsteroidMax: 6
	bonusMediumAsteroidMaxExtra: 4
	bonusSmallAsteroidMaxExtra: 4
	bonusStartTime: 30
	bonusTimeIncrement: 15
	bonusLargeAsteroidScore: 25000
	bonusMediumAsteroid: 50000
	bonusSmallAsteroidScore: 100000
	bonusMaxTimeBonusScore: 500000
	bonusSecsAdded: 0
	
	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]
		@bonusLargeAsteroidMin = parseInt $json.bonusLargeAsteroidMin[0]
		@bonusLargeAsteroidMax = parseInt $json.bonusLargeAsteroidMax[0]
		@bonusMediumAsteroidMaxExtra = parseInt $json.bonusMediumAsteroidMaxExtra[0]
		@bonusSmallAsteroidMaxExtra = parseInt $json.bonusSmallAsteroidMaxExtra[0]
		@bonusStartTime = parseInt $json.bonusStartTime[0]
		@bonusTimeIncrement = parseInt $json.bonusTimeIncrement[0]
		@bonusLargeAsteroidScore = parseInt $json.bonusLargeAsteroidScore[0]
		@bonusMediumAsteroidScore = parseInt $json.bonusMediumAsteroidScore[0]
		@bonusSmallAsteroidScore = parseInt $json.bonusSmallAsteroidScore[0]
		@bonusMaxTimeBonusScore = parseInt $json.bonusMaxTimeBonusScore[0]
		@bonusSecsAdded = parseInt $json.bonusSecsAdded[0]
		
	#Create a new session for new players
	createState: ($spinsTotal,$secsTotal)->
		json =
			spinsLeft: $spinsTotal
			spinsTotal: $spinsTotal
			secsLeft: $secsTotal
			secsTotal: $secsTotal
			winTotal: 0
			bonusGame: null
		return json

	# Split spin function to check ez than
	analyzeResultSpin: (session) ->

		analyzerResultGroup = new AnalyzerResultGroup(session)
		ar = Analyzer.calculate(session,this.reels,1,true,true)
		analyzerResultGroup.add(ar) 
		analyzerResultGroup.process(false)

		session.bonusGame = null

		checkTriggers = analyzerResultGroup.findSymbolWins('B',3,3)
		
		if checkTriggers != null

			largeCount = @bonusLargeAsteroidMin + Math.floor(Math.random() * (@bonusLargeAsteroidMax - @bonusLargeAsteroidMin + 1))
			mediumCount = (largeCount * 2) + Math.floor(Math.random() * @bonusMediumAsteroidMaxExtra)
			smallCount = (mediumCount * 2) + Math.floor(Math.random() * @bonusSmallAsteroidMaxExtra)
			minScore = (largeCount * @bonusLargeAsteroidScore) + (mediumCount * @bonusMediumAsteroidScore) + (smallCount * @bonusSmallAsteroidScore)
			totalWin = minScore + @bonusMaxTimeBonusScore
			
			session.bonusGame = 
				totalWin: totalWin
				asteroids: 
					minScore: minScore
					large:
						count: largeCount
						score: @bonusLargeAsteroidScore
					medium:
						count: mediumCount
						score: @bonusMediumAsteroidScore
					small:
						count: smallCount
						score: @bonusSmallAsteroidScore
				timeBonus:
					maxScore: @bonusMaxTimeBonusScore
					startTime: @bonusStartTime
					timeIncrement: @bonusTimeIncrement

			checkTriggers[0].trigger = 'trigger'
			checkTriggers[0].pay += totalWin

			analyzerResultGroup.addBonusPay("B", totalWin)

		return {
			session: session
			analyzerResultGroup: analyzerResultGroup
		}

	spin: ($state, $request)->
		
		self = @
		session = new SlotSession this
		if $state then	session.importState $state

		spinArr = null

		# Loop till condition is pass
		checkTime = new Date().getTime()

		for i in [0..1000] #1000 Retry Spins!
			spinArr = session.window.spinReels()

			analyze = self.analyzeResultSpin(session)
			
			if(analyze == null)
				continue
			
			session = analyze.session
			analyzerResultGroup = analyze.analyzerResultGroup

			if analyzerResultGroup.findSymbolWins('B',3,3) && session.fsMxTotal >= @maxBonusGameHits
				continue

			result = self.checkConditionsRoll session, analyzerResultGroup

			break if (result)

		#Only add time if there is a pick bonus
		if session.bonusGame
			session.secsTotal += @bonusSecsAdded
			session.secsLeft += @bonusSecsAdded
			session.fsMxTotal++

		#Log a warning if the retry logic took more than 10ms
		operationLimit = 10
		operationTime = new Date().getTime() - checkTime
		if operationTime > operationLimit then console.warn "WARNING -AsteroidsGame: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

		#Add to player
		session.winTotal += analyzerResultGroup.pay
		session.spinsLeft--

		#Send state
		state = session.exportState()
		state.bonusGame = session.bonusGame
		
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
