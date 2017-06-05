#Made by The Engine Company for Kizzang on 2015-08-26
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

class exports.PenguinRichesGame extends SlotGame
	EXPANDING_WILD_SYMBOL = 'W' #The symbol used for wilds created by expansion
	BONUS_MULTIPLIER_SYMBOL = 'BMS' #The symbol used for bonus multipliers
	
	PLACEHOLDER_SYMBOL = '?' #Symbol that safely represents nothing
	
	maxFreeSpinMultiplier: 10
	fsSpinsTotal: 0
	fsMxTotal: 1
	fsSecsAdded: 0
	pickSymbols: null
	avgWin: 0
	
	scatterSymbols = {}
	nonBonusSymbols = []
	
	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@maxFreeSpinMultiplier = parseInt $json.maxFreeSpinMultiplier[0]
		@fsSpinsTotal = parseInt $json.fsSpinsTotal[0]
		@fsMxTotal = parseInt $json.fsMxTotal[0]
		@fsSecsAdded = parseInt $json.fsSecsAdded[0]
		@switchPointsRaw = $json.avgWinDynamicPoints[0]
		@switchPoints = @switchPointsRaw.split ","
		
		#Find the scatters and create an array of non-bonus symbols for replacing bonus symbols in the case of 3 or more 'B' symbols
		for i in $json.symbolGroup[0].symbol
			
			if i.$.scatter == 'Y' 
			
				if i.$.id != 'B' #The 'B' Symbol is a special case that shouldn't be counted here
			
					scatterSymbols[i.$.id] = true
			
			else if i.$.id != EXPANDING_WILD_SYMBOL
				
				nonBonusSymbols.push(i.$.id)


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
			fsMxTotal: 1
			fsWinTotal: 0
			fsWildSymbol: null
		return json
	
	#Returns a special "found scatters" object to be used in the "replaceExtraScatters" method
	findScatters = ($session) ->
		
		session = $session
		
		foundScatters = [];
		for i in [1...session.window.window.length]
			for j in [1...session.window.window[i].length]
			
				sym = session.window.window[i][j]
				
				if scatterSymbols[sym]

					foundScatters.push {sym: sym, index:{i:i, j:j}};
					
		return foundScatters
	
	#Takes a special "found scatters" object and uses that to replace other scatters
	replaceExtraScatters = (foundScatters, $session, replaceSymbol) ->
		
		session = $session
		
		if foundScatters.length > 1
		
			for i in [1...foundScatters.length]
	
				session.window.window[foundScatters[i].index.i][foundScatters[i].index.j] = replaceSymbol

	#Split spin function to check ez than
	analyzeResultSpin: ($session) ->

		session  = $session
		
		#Before we do anything, check if we got a bonus
		bonusCount = 0
		for i in [1...session.window.window.length]
			
			for j in [1...session.window.window[i].length]
			
				if session.window.window[i][j] == 'B'
					
					bonusCount++
		
		if bonusCount >= 3 #3 bonuses lead to a bonus state
		
			#We got a bonus state! Replace all other bonus-type symbols with random other symbols
			for i in [1...session.window.window.length]
			
				for j in [1...session.window.window[i].length]
				
					sym = session.window.window[i][j]
					
					if scatterSymbols[sym] || sym == EXPANDING_WILD_SYMBOL
						
						session.window.window[i][j] = common.shuffle(nonBonusSymbols)[0]
						
		else
			
			#We didn't get a bonus state, do the stuff we need to do to other bonus types
			
			#Handle bonus picks, there should only be one kind of bonus pick on any spin
			#So we mess with the symbols to make this true
			foundScatters = findScatters(session)
				
			#If we found more than 1 scatter, shuffle them and replace all scatters with the leading scatter
			if (foundScatters.length > 1)
			
				foundScatters = common.shuffle(foundScatters)
			
				#Replace extra scatters with chosen scatter
				replaceExtraScatters(foundScatters, session, foundScatters[0].sym)
			
			#Handle expanding wilds and bonus multipliers
			foundBonusMult = 0
			for i in [1...session.window.window.length]
			
				foundWild = false
				for j in [1...session.window.window[i].length]
					
					#Change the symbol to a wild if a wild was already discovered in this row
					if foundWild
						
						session.window.window[i][j] = EXPANDING_WILD_SYMBOL
					
					#Check for a wild
					id = session.window.window[i][j]
					
					if @wilds.indexOf(id) != -1
						
						foundWild = true
						
					#Check for a bonus mult symbol, and increase the mult when there are three available
					if id == BONUS_MULTIPLIER_SYMBOL && session.fsMxTotal < @maxFreeSpinMultiplier
					
						foundBonusMult++;
						
						if foundBonusMult == 3
						
							session.fsMxTotal++
		
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
				session.fsMxTotal = 1
				session.fsWildSymbol = null
				session.fsWinTotal = 0

			#Check triggers, CANNOT pick wild symbol again
			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
			if checkTriggers != null and session.fsSpinsLeft <= 0

				session.fsOn = true
				session.spinsTotal += @fsSpinsTotal
				session.spinsLeft += @fsSpinsTotal
				session.fsSpinsLeft += @fsSpinsTotal
				session.fsSpinsTotal += @fsSpinsTotal
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				session.fsWildSymbol = null
				session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded}
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

				session.fsOn = true
				session.spinsTotal += @fsSpinsTotal
				session.spinsLeft += @fsSpinsTotal
				session.fsSpinsLeft += @fsSpinsTotal
				session.fsSpinsTotal += @fsSpinsTotal
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				session.fsWildSymbol = null
				session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded}
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
		
		if $state.fsOn and $state.fsSpinsLeft>0
			this.importStripGroup json, 'bonus'
		else
			this.importStripGroup json, 'base'



		# Do up to 1000(!) retries to get a spin that meets the desired conditions
		analyze = null
		checkTime = new Date().getTime()
		
		multiplier = session.fsMxTotal
		for i in [0..1000] #1000 Retry Spins!

			#Spin reels, check for cheating
			if not $request or not $request.params.cheat or $request.params.cheat=='?' then spinArr = session.window.spinReels()
			else session.window.setReelsByCode $request.params.cheat
			
			#Before analyzing, set the multiplier to it's original value
			session.fsMxTotal = multiplier
			
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
