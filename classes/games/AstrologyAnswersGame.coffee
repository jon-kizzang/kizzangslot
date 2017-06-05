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

class exports.AstrologyAnswersGame extends SlotGame
	fsSpinsTotal: 0
	fsMxTotal: 0
	avgWin: 0
	mxWildSymbols = []
	maxBonusGameHits: 0

	wheelWedges: []
	freeMoneyWins: []
	bonusTypeChances: []
	secsAddedPerBonus: []
	
	#Import extras for this type of game
	importGame: ($json)->
		super $json

		@wheelWedges = $json.wheelWedges[0].split ","
		@freeMoneyWins = $json.freeMoneyWins[0].split ","
		@bonusTypeChances = $json.bonusTypeChances[0].split ","
		@secsAddedPerBonus = $json.secsAddedPerBonus[0].split ","
		
		@fsSpinsTotal = parseInt $json.fsSpinsTotal[0]
		@fsMxTotal = parseInt $json.fsMxTotal[0]
		@maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]
		
		#Find the wild multipliers
		for i in [0...$json.wildMultiplier[0].symbol.length]
			mxWildSymbols[$json.wildMultiplier[0].symbol[i].$.id] = $json.wildMultiplier[0].symbol[i].$.multiplier
	
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

	#Will return a random pick between P1 and P10 (inclusive)
	randomPick = () ->
		
		#Get a number between 1 and 7
		num = Math.floor((Math.random() * 7) + 1)
		return "P" + num.toString()
		

	analyzeResultSpin: ($session) ->

		session  = $session
		#Analyze
		analyzerResultGroup = new AnalyzerResultGroup session

		#Check trigger
		checkMainBonusTriggers = analyzerResultGroup.findSymbolWins 'B',3,6
		if (checkMainBonusTriggers != null && (session.fsMxTotal > @maxBonusGameHits || session.spinsLeft <= 1))
			return null
				
		session.wheelBonus = null
		session.freeMoney = null
		session.fsTrigger = null
		
		if session.fsOn
			resultGroup = Analyzer.calculate(session,this.reels,1,true,true)

			#We need to manually handle additive multipliers
			if resultGroup != null
				for i in [0...resultGroup.length]
					multiplierTotal = 0
					for j in [0...resultGroup[i].locations.length]
						sym = resultGroup[i].locations[j].symbol
						if mxWildSymbols[sym]
							multiplierTotal += parseInt(mxWildSymbols[sym])
							#console.log "Adding multiplier: " + mxWildSymbols[sym]
					if multiplierTotal == 0
						multiplierTotal = 1
					
					resultGroup[i].mx = multiplierTotal
					resultGroup[i].pay *= multiplierTotal
				
			analyzerResultGroup.add resultGroup

			#Process results
			analyzerResultGroup.process true
			@bonusType = "fs"

		else
			analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

			#Process results
			analyzerResultGroup.process false

			result = @checkConditionsRoll session, analyzerResultGroup
			if(result == false) #initial spin for wheel bonus/free money bonus is to large respin
				return null
			else
				if(checkMainBonusTriggers)
					#need to decide what type of bonus is going to trigger
					@determineBonusType()
					if(@bonusType == "wheel")
						before = analyzerResultGroup.pay
						session.wheelBonus = @handleWheelBonus session
						analyzerResultGroup.pay += parseInt(session.wheelBonus.win)
					else if(@bonusType == "freemoney")
						session.freeMoney = @handleFreeMoney session
						analyzerResultGroup.pay += parseInt(session.freeMoney.win)

		return {
			session: session
			analyzerResultGroup: analyzerResultGroup
		}

	determineBonusType:()->
		randomNum = Math.random()
		if(randomNum < parseFloat(@bonusTypeChances[0]))
			@bonusType = "fs"
		else if(randomNum < parseFloat(@bonusTypeChances[1]))
			@bonusType = "wheel"
		else#handle the last case of just winning money
			@bonusType = "freemoney"

	handleWheelBonus:(session)->
		
		wedges = @shuffleWedges()
		newWedges = []
		
		for i in[0...12]
			newWedges.push wedges[i]

		obj = {
			picks: []
			numSpins: 3,
			numExtraSpins: 0,
			extraSpinCounter: 0,
			totalMultiplier: 0,
			total: 0,
			wedges: newWedges,
			gotFreeSpin: false
			}
		#Start by picking 3 wedges for the user to win, increment # of wedges only if +1 spin is hit
		obj = @getWheelPicks(obj, false)
		while(obj.gotFreeSpin == true)
			obj = @getWheelPicks(obj, true)

		if(obj.totalMultiplier == 0)
			obj.totalMultiplier = 1

		wheelBonus = {
			spins: obj.numSpins,
			extraSpins: obj.numExtraSpins,
			pickIndexes: obj.picks,
			wedges: obj.wedges,
			win: (obj.total * obj.totalMultiplier),
			totalMultiplier: obj.totalMultiplier,
			secs: parseInt(@secsAddedPerBonus[1])
		}

		return wheelBonus

	getWheelPicks:(obj, isExtraSpins)->
		obj.gotFreeSpin = false
		
		if isExtraSpins == true
			numSpins = obj.extraSpinCounter
			obj.extraSpinCounter = 0
		else
			numSpins = obj.numSpins
		
		templength = numSpins + obj.picks.length
		
		originalLength = obj.picks.length
		for i in [originalLength...templength]
			repick = true
			while(repick)#pick a wedge, make sure that it hasnt been picked before
				repick = false
				newPick = parseInt(Math.random() * obj.wedges.length)
				
				for z in[0...obj.picks.length]
					currpick = parseInt(obj.picks[z])
					if(parseInt(currpick) == parseInt(newPick))
						repick = true
				if(obj.picks.length == 0)
					if(obj.wedges[newPick] == "+1 Spin" || obj.wedges[newPick] == "2x" || obj.wedges[newPick] == "3x" || obj.wedges[newPick] == "4x" || obj.wedges[newPick] == "5x")
						repick = true

			if(obj.wedges[newPick] == "+1 Spin")#Add extra spins
				obj.extraSpinCounter++
				obj.gotFreeSpin = true
			else if(obj.wedges[newPick] == "2x" || obj.wedges[newPick] == "3x" || obj.wedges[newPick] == "4x" || obj.wedges[newPick] == "5x")#add to the total multiplier
				obj.totalMultiplier += parseInt(obj.wedges[newPick].substring(0,1))
			else#add point value total
				obj.total += parseInt(obj.wedges[newPick])
			obj.picks[i] = newPick
		
		obj.numExtraSpins = obj.numExtraSpins + obj.extraSpinCounter
		return obj

	shuffleWedges: ()->
		@wheelWedges = common.shuffle @wheelWedges
		return @wheelWedges

	handleFreeMoney:(session)->
		idx = parseInt(Math.random() * @freeMoneyWins.length)
		
		freeMoney = {
			win: @freeMoneyWins[idx],
			secs: parseInt(@secsAddedPerBonus[2])
		}
		
		return freeMoney

	checkBonus: ($analyzer, $session)->
		if(@bonusType == "fs")
			@handleFS $analyzer, $session
		#@bonusType = ""#reset bonus type as to not accidentily trigger something

	#Free spin handling
	handleFS: ($analyzer, $session)->
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
			# If there are less than 0 free spins the bonus game has ended so we can get a new bonus game
			@setupFreeSpinBonus session, analyzerResultGroup
			
			#Track free spins
			session.fsWinTotal += analyzerResultGroup.pay
			if session.fsSpinsLeft<0
				session.fsWinTotal = 0

		#Base games
		else
			#Check first bonus trigger
			session.fsTrigger = null
			@setupFreeSpinBonus session, analyzerResultGroup

	setupFreeSpinBonus:($session, $analyzerResultGroup) ->
		session = $session
		analyzerResultGroup = $analyzerResultGroup
		
		checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,6
		if(checkTriggers != null)
			session.fsOn = true
			session.spinsTotal += @fsSpinsTotal
			session.spinsLeft += @fsSpinsTotal
			session.fsSpinsLeft += @fsSpinsTotal
			session.fsSpinsTotal += @fsSpinsTotal
			session.secsTotal += parseInt(@secsAddedPerBonus[0])
			session.secsLeft += parseInt(@secsAddedPerBonus[0])
			session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:parseInt(@secsAddedPerBonus[0])}
			session.fsMxTotal++

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

			checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,6
			if checkTriggers != null
				#if session.fsSpinsLeft==1#cant hit 2 bonuses in a row, there is now way to check viability of spin or to respin after the fact
				#	continue
				if  session.fsMxTotal < @maxBonusGameHits && session.spinsLeft > 1
					break
			else
				result = self.checkConditionsRoll session, analyzerResultGroup
				break if (result)

		#Log a warning if the retry logic took more than 10ms
		operationLimit = 1000
		operationTime = new Date().getTime() - checkTime
		if operationTime > operationLimit then console.warn "WARNING: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

		if(session.wheelBonus)
			session.secsTotal += parseInt(@secsAddedPerBonus[1])
			session.secsLeft += parseInt(@secsAddedPerBonus[1])
			session.fsMxTotal++
		else if(session.freeMoney)
			session.secsTotal += parseInt(@secsAddedPerBonus[2])
			session.secsLeft += parseInt(@secsAddedPerBonus[2])
			session.fsMxTotal++
		else
			#Handle bonus state
			self.checkBonus analyzerResultGroup, session
		
		#Add to player
		session.winTotal += analyzerResultGroup.pay
		session.spinsLeft--

		#Send state
		state = session.exportState()
		state.fsWildSymbol = session.fsWildSymbol
		state.wheelBonus = session.wheelBonus
		state.freeMoney = session.freeMoney
		
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
