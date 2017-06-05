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

class exports.XtremeCashGame extends SlotGame
	fsSpinsTotal: 0
	fsMxTotal: 0
	fsSecsAdded: 0
	pickSymbols: null
	avgWin: 0
	maxCollapses: 0
	rows: 0
	collapseSymbols: []
	maxBonusGameHits: 0
	chanceForCellToExplode: 0
	chanceForCollapseToOccur: 0

	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@pickSymbols = $json.pickSymbols[0].split ','
		@fsSpinsTotal = parseInt $json.fsSpinsTotal[0]
		@fsMxTotal = parseInt $json.fsMxTotal[0]
		@fsSecsAdded = parseInt $json.fsSecsAdded[0]
		@maxCollapses = parseInt $json.maxCollapses[0]
		@rows = parseInt $json.rows[0]
		@collapseSymbols = $json.collapseSymbolTypes[0].split ','
		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]
		@chanceForCellToExplode = parseFloat $json.chanceForCellToExplode[0]
		@chanceForCollapseToOccur = parseFloat $json.chanceForCollapseToOccur[0]
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
			analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

			#Process results
			analyzerResultGroup.process true

		else
			analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

			#Process results
			analyzerResultGroup.process false

		#find the location of all bonus symbols on the screen, scatter explosions cannot appear in a higher row than these bonus symbols
		maxExplosionSymbolRowByReel = @findBonusLocations session, 'B'

		#Determine the number of collapses
		chanceToCollapse = Math.random()
		if(chanceToCollapse < @chanceForCollapseToOccur)
			numOfCollapses = 0
		else
			numOfCollapses = parseInt(Math.random() * (@maxCollapses+1))#it is possible to have 0 collapses

		session.collapseInfo = {
			collapses: numOfCollapses
			collapseLocations: []
			}
		totalPay = 0

		#setting up the number of explosions that happened on the previous collapse(first round, no explosions are present)
		numExplosionsPerReel = []
		for p in[0...this.reels]
			numExplosionsPerReel.push 3

		#Choose a random symbol to be the exploding symbol
		rand = parseInt(Math.random() * @collapseSymbols.length)
		collapseSym = @collapseSymbols[rand]

		#create the randomized number of collapses
		for h in[0...numOfCollapses]

			bombLocations = []#locations of all of the bombs
			kind = 0

			for j in[0...this.reels]

				#determine the highest row that a new scatter can be placed in
				maxRowLocation = numExplosionsPerReel[j]
				if(maxRowLocation > maxExplosionSymbolRowByReel[j+1])
					maxRowLocation = maxExplosionSymbolRowByReel[j+1]

				#reset the explosion count for this reel
				numExplosionsPerReel[j] = 0

				#iterate through each row until reaching the highest row that an explosion can be on 
				for k in[0...maxRowLocation]
					hasExplosion = Math.random()#Possible to not get an explosion on a reel
					if(hasExplosion < @chanceForCellToExplode)
						location = {
							symbol: collapseSym
							reel: j+1
							row: k+1
						}
						numExplosionsPerReel[j]++
						kind++
						bombLocations.push location
			pays = session.game.symbolGroup.getSymbolById(collapseSym).pays
			
			if(kind > pays.length) then kind = pays.length

			if(kind > 0) then collapseTotal = parseInt(pays[kind-1])
			else collapseTotal = 0

			totalPay += collapseTotal

			obj = {
				pay: collapseTotal
				bombLocations: bombLocations
			}

			if bombLocations.length > 0
				session.collapseInfo.collapseLocations.push obj#These are all of the locations the bombs will be placed for each collapse
			else
				session.collapseInfo.collapses--#randomizer gave us 3 collapses, but this collapse turned out to have no bombs appear

		#do not add the total of this collapse onto the total of the pay if there are no paylines in the current spin
		if analyzerResultGroup.pay >= 0
			analyzerResultGroup.pay += totalPay

		return {
			session: session
			analyzerResultGroup: analyzerResultGroup
		}


	findBonusLocations:(session, symbol) ->
		bonusCount = 0
		maxExplosionSymbolRowByReel = []
		
		for i in [1...session.window.window.length]
			maxExplosionSymbolRowByReel.push 3

		for column in [1...session.window.window.length]
			for row in [1...session.window.window[column].length]
				if session.window.window[column][row] == symbol
					if maxExplosionSymbolRowByReel[column] >= row
						maxExplosionSymbolRowByReel[column] = row-1

		return maxExplosionSymbolRowByReel

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
				session.fsTrigger = null
			else
				session.fsTrigger = null
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
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				session.fsWildSymbol = picks[0]
				session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded,picks:picks}
				checkTriggers[0].trigger = 'trigger'
				session.fsMxTotal++
				session.collapseInfo.collapses = 0
				session.collapseInfo.collapseLocations = []

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
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				session.fsWildSymbol = picks[0]
				session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded,picks:picks}
				checkTriggers[0].trigger = 'trigger'
				session.fsMxTotal++
				session.collapseInfo.collapses = 0
				session.collapseInfo.collapseLocations = []

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
			session = analyze.session
			analyzerResultGroup = analyze.analyzerResultGroup

			result = self.checkConditionsRoll session, analyzerResultGroup

			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
			if checkTriggers != null
				if  session.fsMxTotal < @maxBonusGameHits && session.spinsLeft > 1
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
		state.collapseInfo = session.collapseInfo

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
