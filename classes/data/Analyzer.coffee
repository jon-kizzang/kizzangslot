#Created by Tony Suriyathep on 2013.12.30

#Step through an analyze various wins in a slot game


common = require("../../include/common")

SlotSession = require("./SlotSession").SlotSession

SlotGame = require("./SlotGame").SlotGame

Symbol = require("./Symbol").Symbol

SymbolWindow = require("./SymbolWindow").SymbolWindow

SymbolLocation = require("./SymbolLocation").SymbolLocation

SymbolGroup = require("./SymbolGroup").SymbolGroup

AnalyzerResult = require("./AnalyzerResult").AnalyzerResult



#==================================================================================================#

#Analyze symbol window



class exports.Analyzer





	@calculate: ($session,$reelIdEnd=$session.game.stripGroup.reels,$mx=1,$runBase=true,$runScatter=true)->

		results = []



		#Run base game

		if $runBase==true

			if $session.game.typeDirection=="Normal" #Does normal and reverse

				if $session.game.typeMethod=="Lines"

					results.push result for result in @calculateLines($session,$reelIdEnd,$mx)

				else if $session.game.typeMethod=="AllPays"

					results.push result for result in @calculateAllPays($session,$reelIdEnd,$mx)

			else if $session.game.typeDirection=="TwoWay" #Does normal and reverse

				if $session.game.typeMethod=="Lines"

					results.push result for result in @calculateLines($session,$reelIdEnd,$mx,false) #Normal

					results.push result for result in @calculateLines($session,$reelIdEnd,$mx,true) #Reverse

				else if $session.game.typeMethod=="AllPays"

					results.push result for result in @calculateAllPays($session,$reelIdEnd,$mx,false) #Normal

					results.push result for result in @calculateAllPays($session,$reelIdEnd,$mx,true) #Reverse



		#Run scatters

		if $runScatter==true

			results.push result for result in @calculateScatters($session,$reelIdEnd,$mx)



		#Return results

		if results.length==0 then return null

		else return results





	@calculateLines: ($session,$reelIdEnd=$session.game.stripGroup.reels,$addMx=1,$isReverse=false)->

		results = []



		for i in [1 .. $session.game.lineGroup.lines.length]
			
			pattern = $session.game.lineGroup.getLine(i)

			for j in [0 .. $session.game.symbolGroup.symbols.length-1]

				symbol = $session.game.symbolGroup.symbols[j]

				if symbol.id=='?' then continue

				else if symbol.scatter==true and symbol.wild==false then continue



				#Loop thru all

				wildCount = 0

				equalCount = 0

				endIndex = Math.min($reelIdEnd,symbol.pays.length)



				for kind in [0..endIndex-1]

					#Get reverse

					mx = 0

					if $isReverse==false then symbolMatchId = $session.window.getSymbol(kind+1,pattern.rows[kind])

					else symbolMatchId = $session.window.getSymbol($session.game.stripGroup.reels-1-kind+1,pattern.rows[$session.game.stripGroup.reels-1-kind])



					if symbolMatchId=='?' then break

					symbolMatch = $session.game.symbolGroup.getSymbolById(symbolMatchId)

					if symbolMatch.scatter==true and symbolMatch.wild==false then break



					#Compare symbols

					if symbolMatchId.substr(-1,1)=='?' #Check for wild card

						if symbol.id.length!=symbolMatchId.length or symbol.id.substr(0,symbol.id.length-1)!=symbolMatchId.substr(0,symbolMatchId.length-1) and symbolMatch.wild==false then break

						if symbolMatch.wild==true then wildCount++

						#New multiplier - it's additive!
						if symbolMatch.mx > 1
							mx += symbolMatch.mx
							if mx > 10 then mx = 10

					else

						if symbol.id!=symbolMatch.id and symbolMatch.wild==false then break #Check for normal matches

						if symbolMatch.wild==true then wildCount++
						if symbol.id==symbolMatch.id then equalCount++

						#New multiplier - it's additive!
						if symbolMatch.mx > 1
							mx += symbolMatch.mx
							if mx > 10 then mx = 10

				#if kind>=3 then console.log 'line='+i+' symbol='+symbol.id+' kind='+kind+' pay='+symbol.pays[kind-1]



				#Check negatives

				if kind==0 then continue #No matches

				else if symbol.pays[kind-1]<=0 then continue #No pay at this level



				#Can't use multiplier on self, such as wilds NOTE: This represents and old paradigm. We might come back to it later...

				#if equalCount==kind then mx = 1

				if mx == 0
					mx = 1

				#This line wins

				result = new AnalyzerResult()

				result.reverse = $isReverse

				result.symbol = symbol.id

				result.line = i

				result.wilds = wildCount

				result.matches = 1

				result.kind = kind

				result.mx = mx*$addMx

				result.pay = symbol.pays[kind-1]*$session.betCoins*$session.betDenom*mx*$addMx

				result.locations = []

				for k in [0..kind-1]

					if $isReverse==false then result.locations.push $session.window.getSymbolLocation(k+1,pattern.rows[k])

					else

						loc = $session.window.getSymbolLocation($session.game.stripGroup.reels-1-k+1,pattern.rows[$session.game.stripGroup.reels-1-k])

						loc.reel = pattern.rows.length-k

						result.locations.push loc



				#Replace win if greater
				lineFound = false
				if results.length>0
					
					for k in [0..results.length-1]

						if result.line != results[k].line then continue
						
						lineFound = true;
						
						#There is a special case in the Bounty game where we want the BP1 symbol to be chosen for the highest score
						if $session.game.configuration.$.id == "bounty" and $session.game.stripGroup.id == "bonus"
							
							if symbol.id == "BP1"
								
								results[k] = result
							
							
						else if result.pay>results[k].pay
						
							results[k] = result
						
						break;
					
				
				if !lineFound then results.push result


		return results





	@calculateAllPays: ($session,$reelIdEnd,$addMx=1,$isReverse=false)->

		results = []



		for i in [0 .. $session.game.symbolGroup.symbols.length-1]

			symbol = $session.game.symbolGroup.symbols[i]

			if symbol.id=='?' then continue

			else if symbol.scatter==true and symbol.wild==false then continue


			kind = 0

			matches = 1

			wildCount = 0

			equalCount = 0

			arr = null

			endIndex = Math.min($reelIdEnd,symbol.pays.length)

			for j in [1 .. endIndex]

				rowMatches = 0
				mx = 0

				for k in [1 .. $session.game.stripGroup.rows]

					if $session.window.getSymbol(j,k)=='?' then continue



					#Get reverse?

					if $isReverse==false then symbolMatchLocation = $session.window.getSymbolLocation(j,k)

					else symbolMatchLocation = $session.window.getSymbolLocation($session.game.stripGroup.reels-1-j+1,k)



					#Not the right symbol for this check

					symbolMatch = $session.game.symbolGroup.getSymbolById(symbolMatchLocation.symbol)

					if symbolMatch.scatter==true and symbolMatch.wild==false then continue

					else if symbolMatch.id!=symbol.id and symbolMatch.wild==false then continue



					rowMatches++

					if arr==null then arr = []

					arr.push symbolMatchLocation



					#Count wilds

					if symbolMatch.wild==true then wildCount++



					#Equal

					if symbolMatch.id==symbol.id then equalCount++



					#New multiplier - it's additive!
					if symbolMatch.mx > 1
						mx += symbolMatch.mx
						if mx > 10 then mx = 10

				if rowMatches>0

					kind++

					matches*=rowMatches

				else

					break



			#Check negatives

			if kind==0 then continue #No matches

			else if symbol.pays[kind-1]<=0 then continue #No pay at this level



			#Can't use multiplier on self, such as wilds NOTE: This represents and old paradigm. We might come back to it later...

			#if equalCount==kind then mx = 1

			if mx == 0
				mx = 1

			#This symbol wins

			result = new AnalyzerResult()

			result.reverse = $isReverse

			result.symbol = symbol.id

			result.line = 0

			result.wilds = wildCount

			result.matches = matches

			result.kind = kind

			result.mx = mx*$addMx

			result.pay = symbol.pays[kind-1]*$session.betCoins*matches*mx*$addMx

			result.locations = arr

			results.push result



		return results





	@calculateScatters: ($session,$reelIdEnd,$addMx=1)->

		results = []



		for i in [0 .. $session.game.symbolGroup.symbols.length-1]

			symbol = $session.game.symbolGroup.symbols[i]

			if symbol.id=='?' then continue

			else if symbol.scatter==false then continue



			arr = null

			kind = 0

			wildCount = 0

			seqTotal = $session.game.stripGroup.reels*$session.game.stripGroup.rows

			for j in [1 .. seqTotal]

				mx = 0
				if $session.window.getSymbolBySequence(j)=='?' then continue



				symbolMatchLocation = $session.window.getSymbolLocationBySequence(j)

				symbolMatch = $session.game.symbolGroup.getSymbolById(symbolMatchLocation.symbol)

				#Not the right symbol for this check

				if symbolMatch.scatter==false then continue

				else if symbolMatch.id!=symbol.id and symbolMatch.wild==false then continue


				#Matching scatter found
				kind++

				if arr==null then arr = []

				arr.push symbolMatchLocation



				#Count wilds

				if symbolMatch.wild==true then wildCount++



				#New multiplier - it's additive!
				if symbolMatch.mx > 1
					mx += symbolMatch.mx
					if mx > 10 then mx = 10



			#Check negatives

			if kind==0

				continue

			else if kind > symbol.pays.length  #cap wins

				kind = symbol.pays.length

				continue

			else if symbol.wild==true and wildCount==kind

				continue #its all wilds



			#No pay at this level

			if symbol.pays[kind-1]<=0 then continue

			if mx == 0
				mx = 1

			#This scatter wins

			result = new AnalyzerResult()

			result.reverse = false

			result.symbol = symbol.id

			result.line = 0

			result.wilds = wildCount

			result.matches = 1

			result.kind = kind

			result.mx = mx*$addMx



			#Scatter pay depends on typeMethod

			if $session.game.typeMethod=="Lines"

				# remove mutilpled with betline,betDenom, betCoins

				if symbol.scatter==true

					result.pay = symbol.pays[kind-1]*mx*$addMx

				else

					result.pay = symbol.pays[kind-1]*$session.betCoins*$session.betDenom*$session.betLines*mx*$addMx

			else if $session.game.typeMethod=="AllPays"

				result.pay = symbol.pays[kind-1]*$session.betCoins*mx*$addMx



			result.locations = arr

			results.push result




		return results
		
		
		
		
		
		
		
		
		
		
		
