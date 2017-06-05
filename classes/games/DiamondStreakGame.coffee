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

class exports.DiamondStreakGame extends SlotGame
	fsMxTotal: 0
	avgWin: 0
	maxBonusGameHits: 0

	levelOne: []
	levelTwo: []
	levelThree: []
	levelFour: []
	
	#Import extras for this type of game
	importGame: ($json)->
		super $json

		@levelOne = $json.levelOne[0].split ","
		@levelTwo = $json.levelTwo[0].split ","
		@levelThree = $json.levelThree[0].split ","
		@levelFour = $json.levelFour[0].split ","
		
		@secsAddedPerBonus = parseInt $json.secsAddedPerBonus[0]
		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]
		
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
		session.pickBonus = null
		#Analyze
		analyzerResultGroup = new AnalyzerResultGroup session

		analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

		#Process results
		analyzerResultGroup.process false

		#Check trigger
		checkMainBonusTriggers = analyzerResultGroup.findSymbolWins 'B',3,6

		if(checkMainBonusTriggers != null)
			#do bonus stuff
			#console.log "Trying to come up with a bonus"
			session.pickBonus = @createBonus session, analyzerResultGroup
			analyzerResultGroup.pay += session.pickBonus.total
		return {
			session: session
			analyzerResultGroup: analyzerResultGroup
		}

	createBonus: (session, analyzerResultGroup) ->
		#console.log "BONUS"
		pickBonus = {
			levels: [],
			secs: @secsAddedPerBonus,
			total: 0
		}
		levels = [];
		baseLevels = [@levelOne, @levelTwo, @levelThree, @levelFour]
		
		for i in[0...baseLevels.length]
			if i == 0
				baseLevel = @getLevelLayout baseLevels[i], true
			else
				baseLevel = @getLevelLayout baseLevels[i], false
			
			newLevel = @totalUpLevel baseLevel
			levels.push newLevel
			
			pickBonus.total += newLevel.total
			
			if(newLevel.pooperHit == true)
				break;
		
		pickBonus.levels = levels
		#console.log "Levels: " + JSON.stringify(pickBonus)
		return pickBonus

	getLevelLayout: (baseLevel, preventPooperOnFirstPick)->
		level = @shuffleLevel baseLevel
		
		if preventPooperOnFirstPick
			while(level[0] == "pooper" || level[0] == "complete" || level[0].indexOf("X") >= 0)
				level = @shuffleLevel baseLevel
				#console.log "Preventing complete/pooper on first pick"
		else
			while(level[0] == "complete" || level[0].indexOf("X") >= 0)
				level = @shuffleLevel baseLevel
				#console.log "Preventing complete/pooper on first pick"
		return level

	shuffleLevel: (level)->
		newLevelMixed = common.shuffle level
		return newLevelMixed

	totalUpLevel: (baseLevel) ->
		
		level = {
			values: [],
			win: 0,
			multiplier: 0,
			total: 0
		}
		
		for i in [0...baseLevel.length]
			level.values.push baseLevel[i]
			
			if baseLevel[i] == "complete"
				break
			else if baseLevel[i] == "pooper"
				level.pooperHit = true
				break
			else if baseLevel[i].indexOf("X") >= 0
				level.multiplier += parseInt baseLevel[i].substring(0,1)
			else if baseLevel[i] == "bomb"
				level = @totalUpBombHit baseLevel
				break
			else
				level.win += parseInt baseLevel[i]
		
		if level.multiplier > 0
			level.total = level.win * level.multiplier
		else
			level.total = level.win
		return level

	totalUpBombHit: (baseLevel)->
		level = {
			values: [],
			win: 0,
			multiplier: 0,
			total: 0
		}
		
		level.values = baseLevel
		
		for i in[0...baseLevel.length]
			if(baseLevel[i] == "complete" || baseLevel[i] == "pooper" || baseLevel[i] == "bomb")
				continue
			else if baseLevel[i].indexOf("X") >= 0
				level.multiplier += parseInt baseLevel[i].substring(0,1)
			else
				level.win += parseInt baseLevel[i]
		
		return level

	spin: ($state, $request)->

		self = @

		#Switch strips
		stripJson = this.configuration.stripGroup
		lineJson = this.configuration.lineGroup
		avgWin = parseInt $state.winTotal / ( parseInt $state.spinsTotal - parseInt $state.spinsLeft )
		
		if $state.fsOn and $state.fsSpinsLeft>0
			this.importStripGroup stripJson, 'bonus'
			this.importLineGroup lineJson, 'bonus'
		else
			this.importLineGroup lineJson, 'base'
			this.importStripGroup stripJson, 'base'


		session = new SlotSession this
		if $state
			session.importState $state

		# Loop untill condition is pass and only do a maximum of 1000 retries
		analyze = null
		checkTime = new Date().getTime()

		for i in [0..1000] #1000 Retry Spins!

			#Spin reels, check for cheating
			#if session.spinsLeft == 17 and not session.fsOn then session.window.setReelsByCode 'B,?,B,?,B'
			if not $request or not $request.params.cheat or $request.params.cheat=='?' then spinArr = session.window.spinReels()
			else session.window.setReelsByCode $request.params.cheat

			analyze = self.analyzeResultSpin(session)
			if(analyze == null)
				continue

			session = analyze.session
			analyzerResultGroup = analyze.analyzerResultGroup

			result = self.checkConditionsRoll session, analyzerResultGroup
			
			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,6
			if checkTriggers != null
				if  session.fsMxTotal < @maxBonusGameHits && session.spinsLeft > 1
					#if(result)
						#console.log "Good Bonus Found"
					break
			else
				break if (result)

		#Only add time if there is a pick bonus
		if session.pickBonus
			session.secsTotal += @secsAddedPerBonus
			session.secsLeft += @secsAddedPerBonus
			session.fsMxTotal++
		#Log a warning if the retry logic took more than 10ms
		operationLimit = 1000
		operationTime = new Date().getTime() - checkTime
		if operationTime > operationLimit then console.warn "WARNING: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

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
