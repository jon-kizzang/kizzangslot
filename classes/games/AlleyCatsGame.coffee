common = require("../../include/common")
SlotGame = require("../data/SlotGame").SlotGame
SlotSession = require("../data/SlotSession").SlotSession
SymbolWindow = require("../data/SymbolWindow").SymbolWindow
Analyzer = require("../data/Analyzer").Analyzer
AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup


class exports.AlleyCatsGame extends SlotGame
	bonusPicks: null
	bonusMinPicks: 0
	bonusMaxPicks: 0
	bonusSecsAdded: 0
	maxBonusGameHits: 0

	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@bonusMinPicks = parseInt $json.bonusMinPicks[0]
		@bonusMaxPicks = parseInt $json.bonusMaxPicks[0]
		@bonusSecsAdded = parseInt $json.bonusSecsAdded[0]
		@bonusPicks = $json.bonusPicks[0].split ','
		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]

			
	#Create a new session for new players
	createState: ($spinsTotal,$secsTotal)->
		json =
			spinsLeft: $spinsTotal
			spinsTotal: $spinsTotal
			secsLeft: $secsTotal
			secsTotal: $secsTotal
			winTotal: 0
			pickBonus: null
		return json

		
	analyzeResultSpin: (session) ->
	
		analyzerResultGroup = new AnalyzerResultGroup(session)
		ar = Analyzer.calculate(session,this.reels,1,true,true)
		analyzerResultGroup.add(ar) 
		analyzerResultGroup.process(false)

		session.pickBonus = null

		checkTriggers = analyzerResultGroup.findSymbolWins('B',3,6)

		if checkTriggers != null

			picks = []
			for i in [0 .. @bonusPicks.length-1]
				picks.push(@bonusPicks[i])
			picks = common.shuffle(picks)
			
			while picks[0].substring(0,1) == "x"
				picks = common.shuffle(picks)
			
			r = Math.floor(Math.random() * (@bonusMaxPicks - @bonusMinPicks)) + @bonusMinPicks
			picks[r] = "0"

			win = 0
			multi = 0
			for i in [0 .. picks.length-1]
				if picks[i] == "0" then break
				if picks[i].substring(0,1) == "x"
					multi += parseInt(picks[i].substring(1))
				else
					win += parseInt(picks[i])
						
			if multi == 0
				multi = 1

			total = win * multi

			session.pickBonus = {picks:picks, total:total, win:win, secs:@bonusSecsAdded}

			checkTriggers[0].trigger = 'trigger'
			checkTriggers[0].pay += total

			analyzerResultGroup.addBonusPay("B", total)

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

		for i in [0..1000] 
			spinArr = session.window.spinReels()

			analyze = self.analyzeResultSpin(session)
			
			if(analyze == null)
				continue
			
			session = analyze.session
			analyzerResultGroup = analyze.analyzerResultGroup
			
			if analyzerResultGroup.findSymbolWins('B',3,6) && session.fsMxTotal >= @maxBonusGameHits
				continue

			result = self.checkConditionsRoll session, analyzerResultGroup

			break if (result)

		#Only add time if there is a pick bonus
		if session.pickBonus
			session.secsTotal += @bonusSecsAdded
			session.secsLeft += @bonusSecsAdded
			session.fsMxTotal++

		#Log a warning if the retry logic took more than 10ms
		operationLimit = 10
		operationTime = new Date().getTime() - checkTime
		if operationTime > operationLimit then console.warn "WARNING -AlleyCatsGame: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

		#Add to player
		session.winTotal += analyzerResultGroup.pay
		session.spinsLeft--

		#Send state
		state = session.exportState()
		state.pickBonus = session.pickBonus

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
