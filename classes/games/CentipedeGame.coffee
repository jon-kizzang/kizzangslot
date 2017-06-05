common = require("../../include/common")
SlotGame = require("../data/SlotGame").SlotGame
SlotSession = require("../data/SlotSession").SlotSession
SymbolWindow = require("../data/SymbolWindow").SymbolWindow
Analyzer = require("../data/Analyzer").Analyzer
AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup


class exports.CentipedeGame extends SlotGame
	maxBonusGameHits: 3
	bonusSecsAdded: 0
	
	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]
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
		if operationTime > operationLimit then console.warn "WARNING -CentipedeGame: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

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
