#Created by Tony Suriyathep on 2013.12.30
#Code to analyze and run a Line based slot game

common = require("../../include/common")
SlotGame = require("../data/SlotGame").SlotGame
SlotSession = require("../data/SlotSession").SlotSession
SymbolWindow = require("../data/SymbolWindow").SymbolWindow
Analyzer = require("../data/Analyzer").Analyzer
AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup


#==================================================================================================#
#Actual game

class exports.MonkeyMadnessGame extends SlotGame
	pickBags: null
	pickSecsAdded: 0
	maxBonusGameHits: 0
	scatterBonusChoices = []
	
	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@pickSecsAdded = parseInt $json.pickSecsAdded[0]

		@pickBags = $json.pickBags[0].split ','
		for i in [0 .. @pickBags.length-1]
			@pickBags[i] = @pickBags[i]

		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]
		@scatterBonusChoices = $json.scatterBonusChoices[0].split ","

	#Create a new session for new players
	createState: ($spinsTotal,$secsTotal)->
		json =
			spinsLeft: $spinsTotal
			spinsTotal: $spinsTotal
			secsLeft: $secsTotal
			secsTotal: $secsTotal
			winTotal: 0
			pickBonus: null
			fsMxTotal: 0
		return json

	# Split spin function to check ez than
	analyzeResultSpin: (session) ->

		session.scatterBonus = null
		#Analyze
		analyzerResultGroup = new AnalyzerResultGroup session
		analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

		#Process results
		analyzerResultGroup.process false

		#Check trigger
		checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
		
		scatterCount = @countSymbol(session, "S")
		if(checkTriggers != null && scatterCount >= 3)
			return null
		
		if(scatterCount >= 3)
			session.scatterBonus = @createScatterBonus(session, scatterCount, analyzerResultGroup)
		
		else if checkTriggers != null
			#Copying pickBags
			bags = []
			for i in [0...@pickBags.length]
				bags.push @pickBags[i]
			bags = common.shuffle bags
			
			#Reshuffle if losing index is first index or if multiplier hits first
			while(String(bags[0]).indexOf("X") >= 0 || parseInt(bags[0]) == 0)
				bags = common.shuffle bags

			#Update value of bags
			win = 0
			total = 0
			totalMultiplier = 0
			dontAdd = false
			for i in [0 .. @pickBags.length-1]
				if parseInt(bags[i]) == 0
					break#no more winnings
				else
					if String(bags[i]).indexOf("X") > -1
						totalMultiplier += parseInt(bags[i].substring(0,1))
					else#value is an integer
						bags[i] = parseInt(bags[i]) * session.getTotalWager()
						win += parseInt(bags[i])
						total += parseInt(bags[i])

			if totalMultiplier == 0
				totalMultiplier = 1

			session.pickBonus = {totalMultiplier:totalMultiplier,bags:bags,win:win,total:total*totalMultiplier,secs:@pickSecsAdded}

			#The scatter win receives the wins of the picks
			checkTriggers[0].trigger = 'trigger'
			checkTriggers[0].pay += total*totalMultiplier

			#Process results
			analyzerResultGroup.pay += total*totalMultiplier

		#No bonus
		else
			session.pickBonus = null

		return {
			session: session
			analyzerResultGroup: analyzerResultGroup
		}

	createScatterBonus:(session, scatterCount, analyzerResultGroup) ->
		analyzerResultGroup.pay -= 10000
		wildCount = @countSymbol(session, "W")

		scatterBonus = []
		
		#copying scatterbonus choices
		bonusChoices = []
		for i in [0...@scatterBonusChoices.length]
			bonusChoices.push @scatterBonusChoices[i]
		bonusChoices = common.shuffle bonusChoices
		
		#select the winning pick, if wilds are not on the board, then it cannot be a wild pick
		picked = false
		while picked == false
			currB = bonusChoices[0]
			if(String(currB).indexOf("W") >= 0)#wild Bonus
				if wildCount <= 0
					bonusChoices.splice(0,1)
					bonusChoices.push "W"
					continue
			picked = true
		
		scatterBonus.push @determineScatterType(bonusChoices, analyzerResultGroup, true)
		scatterCount--
		
		#pick all of the other possible wins, they can be any
		for i in[0...scatterCount]
			scatterBonus.push @determineScatterType(bonusChoices, analyzerResultGroup, false)
		
		#create losing scatter picks, based on the number of scatterCount
		return scatterBonus

	determineScatterType:(bonusChoices, analyzerResultGroup, shouldAddToTotal) ->
		
		if(bonusChoices.length == 0)#exhausted all other options
			console.log "Bonus Choice length hit 0"
			scatterBonus = @createWildScatterBonus()
		else if(bonusChoices[0] == undefined)#exhausted all other options
			console.log "Bonus Choice[0] is undefined"
			scatterBonus = @createWildScatterBonus()
		
		currB = bonusChoices[0]
		
		scatterBonus = {}
		if(currB == undefined)#exhausted all other options
			console.log "currB is undefined"
			return @createWildScatterBonus()
		if(currB.indexOf("W") >= 0)
			scatterBonus = @createWildScatterBonus()
		else if(currB.indexOf("X") >= 0)#multiplier bonus
			scatterBonus = @createMultiplierScatterBonus(analyzerResultGroup, shouldAddToTotal, bonusChoices[0])
		else#free money bonus
			scatterBonus = @createFreeMoneyScatterBonus(analyzerResultGroup, shouldAddToTotal, parseInt(bonusChoices[0]))
		
		bonusChoices.splice(0,1)
		
		return scatterBonus

	createFreeMoneyScatterBonus:(analyzerResultGroup, shouldAddToTotal, amount) ->
		scatterBonus = {}
		scatterBonus.type = "FreeMoney"
		scatterBonus.amount = amount
		
		if(shouldAddToTotal)
			analyzerResultGroup.pay += amount
		
		return scatterBonus

	createMultiplierScatterBonus:(analyzerResultGroup, shouldAddToTotal, multiplier) ->
		scatterBonus = {}
		scatterBonus.type = "Multiplier"
		scatterBonus.multiplier = multiplier
		mult = multiplier.substring(0,1)
		if(shouldAddToTotal)
			analyzerResultGroup.pay = analyzerResultGroup.pay * mult
		return scatterBonus

	createWildScatterBonus:() ->
		scatterBonus = {}
		scatterBonus.type = "Wilds"
		return scatterBonus

	countSymbol:(session, symbol) ->
		count = 0
		for column in [1...session.window.window.length]
			for row in [0...session.window.window[column].length]
				if session.window.window[column][row] == symbol
					#We found a scatter!
					count++
		return count

	spin: ($state, $request)->
		
		self = @
		session = new SlotSession this
		if $state then	session.importState $state

		spinArr = null

		# Loop till condition is pass
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
			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3

			if checkTriggers != null
				if  session.fsMxTotal < @maxBonusGameHits && session.spinsLeft > 1
					break if (result)
			else
				break if (result)

		#Only add time if there is a pick bonus
		if session.pickBonus
			session.secsTotal += @pickSecsAdded
			session.secsLeft += @pickSecsAdded
			session.fsMxTotal++

		#Log a warning if the retry logic took more than 10ms
		operationLimit = 10
		operationTime = new Date().getTime() - checkTime
		if operationTime > operationLimit then console.warn "WARNING -MonkeyMadnessGame: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

		#Add to player
		session.winTotal += analyzerResultGroup.pay
		session.spinsLeft--

		#Send state
		state = session.exportState()
		state.pickBonus = session.pickBonus
		state.scatterBonus = session.scatterBonus
		
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
