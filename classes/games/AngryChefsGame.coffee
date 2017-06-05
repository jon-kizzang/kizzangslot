#Created by Tony Suriyathep on 2013.12.30, Modified by Phillip Dean on 2014.10.15
#Code to analyze and run a Line based slot game
#This is a test pull request
common = require("../../include/common")

SlotGame = require("../data/SlotGame").SlotGame

SlotSession = require("../data/SlotSession").SlotSession

SymbolWindow = require("../data/SymbolWindow").SymbolWindow

Analyzer = require("../data/Analyzer").Analyzer

AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup



#==================================================================================================#
#Actual game


class exports.AngryChefsGame extends SlotGame
	fsSpinsTotal: 0
	fsMxTotal: 0
	fsSecsAdded: 0

	#Import extras for this type of game
	importGame: ($json)->
		super $json
		@fsSpinsTotal = parseInt $json.fsSpinsTotal[0]
		@fsMxTotal = parseInt $json.fsMxTotal[0]
		@fsSecsAdded = parseInt $json.fsSecsAdded[0]
		@pickSecsAdded = parseInt $json.pickSecsAdded[0]
		@bonusList = $json.bonusList[0]
		@bonusArray = @bonusList.split ","
		@bonusPayouts = $json.bonusGroupPayout[0].payout
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
			pickBonus: null

		return json

	analyzeResultSpin: (session) ->

		#Analyze
		analyzerResultGroup = new AnalyzerResultGroup session

		#Process wins
		analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

		#Process results
		analyzerResultGroup.process false

		# Return the session after analyzer and analyzerResultGroup after calculate
		#Check Bonus trigger
		checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,6

		if checkTriggers != null
			bonusArray = common.shuffle @bonusArray
			bonusArray = bonusArray[0..14]
			c1 = 0
			c2 = 0
			c3 = 0
			c4 = 0
			mx = []
			totalMx = 0
			bonusWinAmount = 0
			for i in [0 .. @bonusArray.length-1]
				if @bonusArray[i]=='c1' then c1++
				else if @bonusArray[i]=='c2' then c2++
				else if @bonusArray[i]=='c3' then c3++
				else if @bonusArray[i]=='c4' then c4++
				else if @bonusArray[i]=='2' || @bonusArray[i]=='3' || @bonusArray[i]=='5' then mx.push @bonusArray[i]

				if c1==parseInt @bonusPayouts[ 0 ]['$']['match']
					bonusWinAmount= parseInt @bonusPayouts[ 0 ]['$']['value']
					break
				else if c2==parseInt @bonusPayouts[ 1 ]['$']['match']
					bonusWinAmount= parseInt @bonusPayouts[ 1 ]['$']['value']
					break
				else if c3==parseInt @bonusPayouts[ 2 ]['$']['match']
					bonusWinAmount= parseInt @bonusPayouts[ 2 ]['$']['value']
					break
				else if c4==parseInt @bonusPayouts[ 3 ]['$']['match']
					bonusWinAmount= parseInt @bonusPayouts[ 3 ]['$']['value']
					break

			# Find bonus multiplier amount
			if mx.length > 0
				for i in [0 .. mx.length-1]
					totalMx += parseInt mx[ i ]
			else
				totalMx = 1

			# Times by multiplier
			total = bonusWinAmount * totalMx

			# Create Bonus Obj
			session.pickBonus = {chefs:bonusArray,win:bonusWinAmount,mx:totalMx, bonusWin:total, totalWin: total + analyzerResultGroup.pay }

			#The scatter win receives the wins of the picks
			checkTriggers[0].pay += total

			#Process bonus results
			analyzerResultGroup.pay += total
			analyzerResultGroup.profit += total

		else
			session.pickBonus = null

		return {
			session: session
			analyzerResultGroup: analyzerResultGroup
		}

	spin: ($state, $request)->
		
		self = @
		session = new SlotSession this
		if $state then session.importState $state

		#Switch strips
		json = session.window.slotGame.configuration.stripGroup
		avgWin = parseInt session.winTotal
		# / ( parseInt session.spinsTotal - parseInt session.spinsLeft )

		if avgWin < parseInt @switchPoints[0]
  			session.window.slotGame.importStripGroup json, "base"
		else if avgWin < parseInt @switchPoints[1]
  			session.window.slotGame.importStripGroup json, "base1"
		else if avgWin < parseInt @switchPoints[2]
  			session.window.slotGame.importStripGroup json, "base2"
		else if avgWin < parseInt @switchPoints[3]
	  		session.window.slotGame.importStripGroup json, "base3"
		else if avgWin >= parseInt @switchPoints[3]
  			session.window.slotGame.importStripGroup json, "base4"
		else
			session.window.slotGame.importStripGroup json, "base5"

		spinArr = null

		# Loop till condition is pass

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
			
		#Only add time if there is a pick bonus
		if session.pickBonus
			session.secsTotal += @pickSecsAdded
			session.secsLeft += @pickSecsAdded

		#Log a warning if the retry logic took more than 10ms
		operationLimit = 10
		operationTime = new Date().getTime() - checkTime
		if operationTime > operationLimit then console.warn "WARNING -AngryChefsGame: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

		#Add to player
		session.winTotal += analyzerResultGroup.pay
		session.spinsLeft--

		state = session.exportState()
		state.bonusPick = session.pickBonus
		delete state.fsOn
		delete state.fsSpinsLeft
		delete state.fsSpinsTotal
		delete state.fsMxTotal
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
