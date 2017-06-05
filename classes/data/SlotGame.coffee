#Created by Tony Suriyathep on 2013.12.30



SymbolGroup = require('./SymbolGroup').SymbolGroup

Symbol = require('./Symbol').Symbol

StripGroup = require('./StripGroup').StripGroup

Strip = require('./Strip').Strip

LineGroup = require('./LineGroup').LineGroup

Line = require('./Line').Line

ProbabilityGroup = require('./ProbabilityGroup').ProbabilityGroup

Probability = require('./Probability').Probability





#==================================================================================================#

#Data of a slotgame





class exports.SlotGame



	#Game

	id: null #keep it lowercase no spaces or underscores

	configuration: null

	typeMethod: 'Lines' #Lines,AllPays

	typeDirection: 'Normal' #Normal,TwoWay

	typeCascading: false

	allowCheat: false

	denomDefault: 1

	denomList: null

	coinDefault: 0

	coinList: null

	lines: 1 #Total lines

	symbolGroup: null #Current group

	lineGroup: null #Current group

	stripGroup: null #Current group

	probabilityGroup: null #Current group
	
	wilds: [] #An array of symbols that are marked as being wild

	fsSpinTotal: 3

	fsMxTotal: 1

	# Add new value

	minGameTotal: null

	maxGameTotal: null

	avgGameTotal: null

	maxBonusGamesHits: null
	
	bonusGameNoHitSpins: null

	minSingleSpinAmount: null

	maxSingleSpinAmount: null

	lastValueSpin: 0

	constructor: (@id)-> return



	#Return the bet ID for this amount

	findCoinIdByAmount: (coin)->

		for i in [0..@coinList.length-1]

			if @coinList[i] == coin then return i

		return -1



	#Return the denom ID for this amount

	findDenomIdByAmount: (denom)->

		for i in [0..@denomList.length-1]

			if @denomList[i] == denom then return i

		return -1



	#Import line group from json

	importLineGroup: (json,id = null)->

		if not json then return

		for n in json

			if n.$.id == id or not id

				@lineGroup = LineGroup.importFromXml n

				break #1 only

		@lines = @linesDefault = @lineGroup.lines.length



	#Import line group from json

	importSymbolGroup: (json,id = null)->
		
		if not json then return
		
		for n in json
			
			for m in n.symbol
				
				if m.$.wild == 'Y' #'Y' represents a 'true' value
				
					@wilds.push(m.$.id)
			
			if n.$.id == id or not id

				@symbolGroup = SymbolGroup.importFromXml n

				break #1 only



	#Import line group from json

	importStripGroup: (json,id = null)->

		if not json then return

		for n in json

			if n.$.id == id or not id
				
				#Set the number of strips to match the StripGroup
				@reels = n.$.reels
				
				@stripGroup = StripGroup.importFromXml n

				#console.log 'imported '+n.$.id+' = '+id

				break #1 only



	#Import line group from json

	importProbabilityGroup: (json,id = null)->

		if not json then return

		for n in json

			if n.$.id == id or not id

				@probabilityGroup = ProbabilityGroup.importFromXml n

				break #1 only


	# Function check conditional of win amount include bonus amount
	# Return true false

	checkConditionsRoll: (session, analyzerResultGroup) ->

		self = @

		spinsTotal = parseInt session.spinsTotal

		spinsLeft = parseInt session.spinsLeft

		spinValue = analyzerResultGroup.pay || 0

		# totalScore win include this spinValue
		totalScore = (parseInt session.winTotal) + spinValue

		# Check in range min-max payout each spin
		if (spinValue > self.maxSingleSpinAmount || spinValue < self.minSingleSpinAmount) then return false

		#else if (totalScore < self.avgGameTotal && (spinsTotal - spinsLeft) >= 20) && (spinValue < (self.minGameTotal/(spinsTotal - spinsLeft))) then return false

		# Double-check for the case where total value after 20 times spinning is still 0 (should be impossible if properly configured)

		#else if (totalScore < self.avgGameTotal && (spinsTotal - spinsLeft) >= 20) && (spinValue < (self.minGameTotal/(spinsTotal - spinsLeft))) then return false

		else

			# When spinValue is accepted we will add it to lasteValueSpin for next checking

			@lastValueSpin = spinValue

			return true


	spin: ->

		return null



	#Import single

	importGame: (json)->
		
		@configuration = json

		@typeMethod = json.typeMethod[0]

		@typeDirection = json.typeDirection[0]

		@typeCascading = json.typeCascading[0]

		@coinDefault = parseInt json.coinDefault[0]

		@coinList = json.coinList.toString().split(',').map (val)-> return parseInt val

		@denomDefault = parseInt json.denomDefault[0]

		@denomList = json.denomList.toString().split(',').map (val)-> return parseInt val

		@importLineGroup json.lineGroup, null

		@importSymbolGroup json.symbolGroup, null

		@importStripGroup json.stripGroup, null

		@importProbabilityGroup json.probabilityGroup, null

		# Add change new info rule for slot game
		@minGameTotal = parseInt json.minGameTotal[0]

		@maxGameTotal = parseInt json.maxGameTotal[0]

		@avgGameTotal = parseInt json.avgGameTotal[0]

		@maxBonusGamesHits = parseInt json.maxBonusGamesHits[0]

		@minSingleSpinAmount = parseInt json.minSingleSpinAmount[0]

		@bonusGameNoHitSpins = json.bonusGameNoHitSpins

		@minSingleSpinAmount = parseInt json.minSingleSpinAmount[0]

		@maxSingleSpinAmount = parseInt json.maxSingleSpinAmount[0]

		### END ###










