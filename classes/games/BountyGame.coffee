#Created by The Engine Company on 2015.10.19
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

class exports.BountyGame extends SlotGame
	fsSpinsTotal: 0
	fsMxTotal: 0
	fsSecsAdded: 0
	avgWin: 0
	scatterSymbols = []
	mxWildSymbols = []
	maxBonusGameHits: 0
	currentBonusGameHits: 0
	
	#Hardcode the special scatters for the bonus chest
	scatterSymbols["S2"] = true
	scatterSymbols["S3"] = true
	scatterSymbols["S4"] = true
	
	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@fsSpinsTotal = parseInt $json.fsSpinsTotal[0]
		@fsMxTotal = parseInt $json.fsMxTotal[0]
		@fsSecsAdded = parseInt $json.fsSecsAdded[0]
		@switchPointsRaw = $json.avgWinDynamicPoints[0]
		@switchPoints = @switchPointsRaw.split ","
		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]
		
		#Find the wild multipliers
		for i in [0...$json.wildMultiplier[0].symbol.length]
			mxWildSymbols[$json.wildMultiplier[0].symbol[i].$.id] = $json.wildMultiplier[0].symbol[i].$.multiplier
		
	#Create a new session for new players
	createState: ($spinsTotal,$secsTotal)->
		@currentBonusGameHits = parseInt(($spinsTotal - 26) / @fsSpinsTotal);
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
	
	#Will return a random pick between P1 and P10 (inclusive)
	randomPick = () ->
		
		#Get a number between 1 and 10
		num = Math.floor((Math.random() * 10) + 1)
		return "P" + num.toString()
	
	analyzeResultSpin: ($session) ->
		
		session  = $session
					
		#If we are not in the bonus state and we got a bonus, we need to make sure we have fewer than 3 Wild and scatter symbols
		if (!session.fsOn)
			
			wildData = []
			scatterData = []
			bonusCount = 0
			for i in [1...session.window.window.length]
				
				for j in [1...session.window.window[i].length]
				
					if session.window.window[i][j] == 'B'
						
						bonusCount++
						
					if session.window.window[i][j] == 'W'
					
						wildData.push({i:i, j:j})
						
					if scatterSymbols[session.window.window[i][j]]
					
						scatterData.push({i:i, j:j})
			
			if bonusCount >= 3 #3 bonuses lead to a bonus state
			
				#We got a bonus state! Make sure we have fewer than 3 wilds
				if (wildData.length >= 3)
					
					common.shuffle(wildData)
					
					for i in [2...wildData.length]
					
						session.window.window[wildData[i].i][wildData[i].j] = randomPick()
				
				#Make sure we have fewer than 3 scatters
				if (scatterData.length >= 3)
					
					common.shuffle(scatterData)
					
					for i in [2...scatterData.length]
					
						session.window.window[scatterData[i].i][scatterData[i].j] = randomPick()
						
			#Find and replace special bonus scatters
			foundScatters = findScatters(session)
			
			if (foundScatters.length > 1)
				
				#If there are more than 3 special scatters, shuffle and replace!
				common.shuffle(foundScatters)
				
				replaceExtraScatters(foundScatters, session, foundScatters[0].sym)
			
			session.fsMxTotal = this.fsMxTotal
		
		#Analyze
		analyzerResultGroup = new AnalyzerResultGroup session

		if session.fsOn
			resultGroup = Analyzer.calculate(session,this.reels,1,true,true)
			
			#We need to manually handle additive multipliers
			if resultGroup != null
				for i in [0...resultGroup.length]
					@fsMxTotal = 0
					for j in [0...resultGroup[i].locations.length]
						sym = resultGroup[i].locations[j].symbol
						if mxWildSymbols[sym]
							@fsMxTotal += parseInt(mxWildSymbols[sym])
							
					if @fsMxTotal == 0 then @fsMxTotal = 1
					
					resultGroup[i].mx = @fsMxTotal
					resultGroup[i].pay *= @fsMxTotal
				
			analyzerResultGroup.add resultGroup

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
				session.fsTrigger = null
			else
				# All bonus symbols present give another free spin during a bonus game! (When there are > 3 symbols)
				bonusCount = 0
				for i in [1...session.window.window.length]
					
					for j in [1...session.window.window[i].length]
					
						if session.window.window[i][j] == 'BB'
							
							bonusCount++
				
				if(bonusCount >= 3)
					session.fsSpinsLeft += bonusCount
					session.fsSpinsTotal += bonusCount
					session.spinsTotal += bonusCount
					session.spinsLeft += bonusCount
				
				session.fsTrigger = null
				
			# If there are less than 0 free spins the bonus game has ended so we can get a new bonus game
			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
			if checkTriggers != null
				session.fsOn = true
				session.spinsTotal += @fsSpinsTotal
				session.spinsLeft += @fsSpinsTotal
				session.fsSpinsLeft += @fsSpinsTotal
				session.fsSpinsTotal += @fsSpinsTotal
				session.fsMxTotal = @fsMxTotal
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded}
				checkTriggers[0].trigger = 'trigger'
				@currentBonusGameHits++
				
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

				session.fsOn = true
				session.spinsTotal += @fsSpinsTotal
				session.spinsLeft += @fsSpinsTotal
				session.fsSpinsLeft += @fsSpinsTotal
				session.fsSpinsTotal += @fsSpinsTotal
				session.fsMxTotal = @fsMxTotal
				session.secsTotal += @fsSecsAdded
				session.secsLeft += @fsSecsAdded
				session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded}
				checkTriggers[0].trigger = 'trigger'
				@currentBonusGameHits++


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
		respins = 0
		
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
					respins++
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
