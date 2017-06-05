#Created by Tony Suriyathep on 2013.12.30



#==================================================================================================#

#Sort and sum results



class exports.AnalyzerResultGroup



	session: null

	wager: 0

	pay: 0 #Total pay all results

	profit: 0 #Less wager

	triggers: null #All triggers not unique

	lines: null #Unique lines involved in wins

	results: null #Array of AnalyzerResult



	constructor: (@session)-> 

		@wager = 0

		@pay = 0

		@results = []

		@lines = []

		@triggers = []



	#Add one AnalyzerResult or an array of AnalyzerResult

	add: (results)-> #An array of results

		if results==null or results.length==0 then return

		if results instanceof Array #Push multiple results

			for i in [0..results.length-1] 

				@results.push results[i]

		else @results.push results #One result?



	#Process all the results by summing and sorting

	process: (freeSpinsOn=false,doSort=true)->

		if freeSpinsOn==false then @wager = @session.getTotalWager()

		else @wager = 0



		#Nothing todo

		if @results.length==0  

			@profit=-@wager

			return



		#Sum

		@pay = 0

		@lines = []

		@triggers = []

		if @results.length>0

			for i in [0..@results.length-1]

				@pay += @results[i].pay

				@lines.push @results[i].line unless @results[i].line==0 or @results[i].line in @lines #Push uniques lines only

				@triggers.push @results[i].trigger unless @results[i].trigger==null #Push uniques lines only



		#Sort data

		if doSort

			@lines.sort (a,b) -> a-b 

			@triggers.sort (a,b) -> a-b

			@results.sort (a,b)-> 

				if a.trigger!=null and b.trigger==null then return -1 #Triggers go first

				else if a.trigger==null and b.trigger!=null then return 1

				else if a.pay<b.pay then return 1 #Pay

				else if a.pay>b.pay then return -1

				else 

					if a.wilds>b.wilds then return -1 #Num of wilds

					else if a.wilds<b.wilds then return 1

					else if a.line>b.line then return -1 #Highest lines

					else if a.line<b.line then return 1

					else #Reverse or not

						if a.reverse==false and b.reverse==true then return -1

						else if a.reverse==true and b.reverse==false then return 1

				return 0



		@profit = @pay - @wager



	#Return an array of reels that have wilds in it with counts such as [0,3,1,2,0]

	getReelsConnectingWilds: ()->

		if @results.length==0 then return null

		#Clear array that is the size of the reels

		arr = []

		for i in [1..@session.game.reels]

			arr[i] = 0



		#Add 1 to every wild on that reel

		for i in [0..@results.length-1]

			for j in [0..@results[i].locations.length-1]

				loc = @results[i].locations[j];

				if loc.symbol.wild==true then arr[loc.reelId]++



		return arr



	#Return results that have that symbol as its primary

	findSymbolWins: (symbol,kindMin=3,kindMax=@game.slotGame.reels)->
		
		#Determine if the symbol has score
		#session.game.configuration.symbolGroup[0].symbol
		symbols = @session.game.configuration.symbolGroup[0].symbol
		firstWinIndex = Infinity
		for i in [0...symbols.length]
			if(symbols[i].$.id == symbol)
			
				pays = symbols[i].$.pays.split(',')
				for j in [0...pays.length]
					if (parseInt(pays[i]) > 0)
					
						firstWinIndex = i;
						break;
				break;
				
		#There are two seperate serch paths, depending on the previous algorithm
		if firstWinIndex < kindMin
		
			if @results.length==0 then return null
	
			arr = []
	
			for i in [0..@results.length-1]
	
				if @results[i].symbol!=symbol then continue
	
	
	
				#Push if in range
	
				if @results[i].kind>=kindMin and @results[i].kind<=kindMax 
	
					arr.push @results[i]
	
	
	
			if arr.length>0 then return arr
	
			return null
			
		else
			
			bonusCount = 0
			for i in [1...@session.window.window.length]
				for j in [1...@session.window.window[i].length]
					
					if @session.window.window[i][j] == symbol
						bonusCount++
						
			if bonusCount >= kindMin and bonusCount <= kindMax
				
				return [ {pay: 0} ]
			
			else 
			
				return null
	

	#Find the win of a line

	findLineWin: (line)->

		if @results.length==0 then return null



		arr = []

		for i in [0..@results.length-1]

			if @results[i].line!=line then continue

			arr.push results[i]



		if arr.length>0 then return arr

		return null
		
		
	#Set the pay for the bonus line
	
	addBonusPay: (bonusSymbol, bonusPay)->
	
		for i in [0..@results.length-1]
		
			if @results[i].symbol == bonusSymbol
			
				@pay -= @results[i].pay
				@pay += bonusPay
				@results[i].pay = bonusPay
				return









