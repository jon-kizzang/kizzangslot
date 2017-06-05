#Created by Tony Suriyathep on 2013.12.30



common = require("../../include/common")

SymbolLocation = require("./SymbolLocation").SymbolLocation



#==================================================================================================#

#Group of symbols



class exports.SymbolWindow

        

        slotGame: null #Array of Symbol

        window: null #Array of symbol ID, with symbols inside



        constructor: (slotGame)->

                if slotGame==null then return

                @slotGame = slotGame
                
                @window=[]

                for i in [1..@slotGame.stripGroup.reels] 

                        @window[i]=[]

                        for j in [1..@slotGame.stripGroup.rows]

                                @window[i][j]='?'



        toJSON: ->

                return @export()



        export: ->

                window = []

                for i in [1..@slotGame.stripGroup.reels] 

                        window[i-1]=[]

                        for j in [1..@slotGame.stripGroup.rows]

                                window[i-1].push @window[i][j]

                return window



        import: (windowObj)->

                @window = []

                for i in [1..@slotGame.stripGroup.reels] 

                        @window[i] = []

                        for j in [1..@slotGame.stripGroup.rows]

                                @window[i][j] = windowObj[i-1][j-1]



#--------------------------------------------------------------------------------------------------#

        #Special spin-type functions



        #Is this empty

        isEmpty: ->

                c = 0

                for i in [1..@slotGame.stripGroup.reels] 

                        for j in [1..@slotGame.stripGroup.rows]

                                if @window[i][j]=='?' then c++

                return c==0



        #Flip reels left to right

        flipReels: -> 

                newWindow = []

                for i in [1..@slotGame.stripGroup.reels] 

                        newWindow[i]=[]

                        for j in [1..@slotGame.stripGroup.rows]

                                newWindow[i][j]=@window[@slotGame.stripGroup.reels-i+1][j]

                @window=newWindow



        #Flip rows  top to bottom

        flipRows: -> 

                newWindow = []

                for i in [1..@slotGame.stripGroup.reels] 

                        newWindow[i]=[]

                        for j in [1..@slotGame.stripGroup.rows]

                                newWindow[i][j]=@window[i][@slotGame.stripGroup.rows-j+1]

                @window=newWindow



        #Spin 1 reel only

        spinReel: (reelId)-> @spinReels(reelId,reelId)



        #Each reel spins, returns the stops per reel

        spinReels: (reelIdStart=1,reelIdEnd=@slotGame.stripGroup.reels)-> 

                arr = []

                for i in [reelIdStart..reelIdEnd]

                        r = @slotGame.stripGroup.getRandomStop(i)

                        arr.push r

                        for j in [1..@slotGame.stripGroup.rows]

                                @setSymbol(i,j,@slotGame.stripGroup.getSymbol(i,r+j-1))

                return arr



        #Stop a reel

        spinReelByStop: (reelId,stop)->

                newSymbolsId = @slotGame.stripGroup.getSymbolsByStop(reelId,stop,@slotGame.stripGroup.rows)

                @setSymbolsByReel(reelId,newSymbolsIds.toString())



        #Use an array of stops to spin reels

        spinReelsByStops: (stops)->

                for i in [0..stops.length-1]

                        newSymbolsIds = @slotGame.stripGroup.getSymbolsByStop(i+1,stops[i],@slotGame.stripGroup.rows)

                        @setSymbolsByReel(i+1,newSymbolsIds.toString())



        #Use an array of stops to set reels such as ("N,N,N,N,N",[1,-1,0,1,1])

        spinReelsBySymbols: (commaDelimSymbolIds,offsetArray=null)->

                symbolIds = commaDelimSymbolIds.split(",")

                for i in [0..symbolIds.length-1]

                        stopOfSymbol = @slotGame.stripGroup.findStopBySymbol(i+1,symbolIds[i])

                        if offsetArray!=null then stopOfSymbol-=offsetArray[i]

                        newSymbolsIds = @slotGame.stripGroup.getSymbolsByStop(i+1,stopOfSymbol,@slotGame.stripGroup.rows)

                        @setSymbolsByReel(i+1,newSymbolsIds.toString())



        #Spin 1 reel only

        spinIndependentReel: (reelId)-> @spinIndependentReels(reelId,reelId)

        

        #Each symbol spins independently

        spinIndependentReels: (reelIdStart=1,reelIdEnd=@slotGame.stripGroup.reels)->

                for i in [reelIdStart..reelIdEnd]

                        for j in [1..@slotGame.stripGroup.rows]

                                @setSymbol(i,j,@slotGame.stripGroup.getRandomSymbol(i))



        #Cascade wins from analyzer result group, symbols replaced are independent

        cascadeReels: (analyzerGroup)->

                #Clear out places that won

                for result in analyzerGroup.results

                        if result.pay==0 then continue

                        for location in result.locations

                                @setSymbol(location.reel,location.row,'?')



                #Store locations of what was added

                ret = new SymbolWindow(@slotGame)



                #Move everything down

                for k in [1..@slotGame.stripGroup.rows]

                        for j in [@slotGame.stripGroup.rows..2] by -1

                                for i in [1..@slotGame.stripGroup.reels]

                                        if @getSymbol(i,j)=='?' then @setSymbol(i,j,@getSymbol(i,j-1))



                #Fill in blanks

                for i in [1..@slotGame.stripGroup.reels]

                        strip = @slotGame.stripGroup.getStrip(i)

                        for j in [1..@slotGame.stripGroup.rows]

                                if @window[i][j]!='?' then continue

                                newSymbolId = strip.getRandomSymbol()

                                @setSymbol(i,j,newSymbolId)

                                ret.setSymbol(i,j,newSymbolId)



                #Window has permanently changed, also return only what was added

                return ret



        #Format S#1,N,N,N,T

        setReelsByCode: (codes)->

                codes = codes.toUpperCase()

                codeArr = codes.split ","



                #Run through and search each reel, dash after symbol ID is the offset

                if codeArr.length==@slotGame.stripGroup.reels

                        for i in [0..codeArr.length-1]

                                symbolArr = codeArr[i].split "-"

                                if symbolArr.length==1  #One entry

                                        if symbolArr[0]=='?'

                                                randomSymbolId = @slotGame.symbolGroup.getRandomSymbolId()

                                                n = @slotGame.stripGroup.findStopBySymbol(i+1,randomSymbolId)

                                                @setSymbolsByReelStop(i+1,n)

                                        else if @slotGame.symbolGroup.getSymbolById(symbolArr[0])

                                                n = @slotGame.stripGroup.findStopBySymbol(i+1,symbolArr[0])

                                                if n==-1

                                                        console.log "SymbolWindow.setReelsByCode: could not find ["+symbolArr[0]+"] that reel will just be randomized"

                                                        randomSymbolId = @slotGame.symbolGroup.getRandomSymbolId()

                                                        n = @slotGame.stripGroup.findStopBySymbol(i+1,randomSymbolId)                

                                                n-=common.randomInteger(0,@slotGame.stripGroup.rows-1)                

                                                @setSymbolsByReelStop(i+1,n)

                                        else

                                                n = parseInt(symbolArr[0])

                                                if n!=0 and not n

                                                        console.log "SymbolWindow.setReelsByCode: could not parse ["+symbolArr[0]+"] that reel will just be randomized"

                                                        randomSymbolId = @slotGame.symbolGroup.getRandomSymbolId()

                                                        n = @slotGame.stripGroup.findStopBySymbol(i+1,randomSymbolId)                                        

                                                @setSymbolsByReelStop(i+1,n)

                                else #Format N-2

                                        n = @slotGame.stripGroup.findStopBySymbol(i+1,symbolArr[0])

                                        if n==-1

                                                console.log "SymbolWindow.setReelsByCode: could not find ["+symbolArr[0]+"] that reel will just be randomized"

                                                randomSymbolId = @slotGame.symbolGroup.getRandomSymbolId()

                                                n = @slotGame.stripGroup.findStopBySymbol(i+1,randomSymbolId)                                                

                                        else

                                                n-=parseInt(symbolArr[1])

                                        @setSymbolsByReelStop(i+1,n)

                        return true



                #set each symbol

                else if codeArr.length==@slotGame.stripGroup.reels*@slotGame.stripGroup.rows

                        for i in [0..codeArr.length-1]

                                n = @slotGame.symbolGroup.getSymbolById(codeArr[i].trim())

                                if not n then n = @slotGame.symbolGroup.getRandomSymbol()        

                                @setSymbolBySequence(i+1,n.id)

                        return true



                #Bad!

                else 

                        throw Error("SymbolWindow.setReelsByCode: Incorrect format "+codes)





#--------------------------------------------------------------------------------------------------#

        #Get and set symbols inside window



        setSymbol: (reelId,rowId,symbolId)-> @window[reelId][rowId]=symbolId 

        

        getSymbol: (reelId,rowId)-> return @window[reelId][rowId]

        

        #Return a SymbolLocation object

        getSymbolLocation: (reelId,rowId)->

                symbolId = @window[reelId][rowId]

                return new SymbolLocation(symbolId,reelId,rowId)

        

        #Return a SymbolLocation object

        getSymbolLocationBySequence: (sequenceId)-> #reels first then rows so last id of 5x3 is 15, 1 based

                rowId = Math.floor((sequenceId-1)/@slotGame.stripGroup.reels)+1

                reelId = sequenceId-((rowId-1)*@slotGame.stripGroup.reels)

                return new SymbolLocation(@window[reelId][rowId],reelId,rowId)



        setSymbolBySequence: (sequenceId,symbolId)-> #reels first then rows so last id of 5x3 is 15

                rowId = Math.floor((sequenceId-1)/@slotGame.stripGroup.reels)+1

                reelId = sequenceId-((rowId-1)*@slotGame.stripGroup.reels)

                @window[reelId][rowId]=symbolId

        

        getSymbolBySequence: (sequenceId)-> #reels first then rows so last id of 5x3 is 15

                rowId = Math.floor((sequenceId-1)/@slotGame.stripGroup.reels)+1

                reelId = sequenceId-((rowId-1)*@slotGame.stripGroup.reels)

                return @window[reelId][rowId] 

        

        setSymbolsByReel: (reelId,commaDelimSymbolIds)->

                symbolIds = commaDelimSymbolIds.split(",")

                if symbolIds.length<@slotGame.stripGroup.rows then throw "SymbolWindow.setSymbolsByReel: bad symbols length "+commaDelimSymbolIds

                for i in [1..@slotGame.stripGroup.rows]

                        @window[reelId][i]=symbolIds[i-1]

        

        getSymbolsByReel: (reelId)->

                arr = []

                for i in [1..@slotGame.stripGroup.rows]

                        arr.push @window[reelId][i]

                return arr



        setSymbolsByRow: (rowId,commaDelimSymbolIds)->

                symbolIds = commaDelimSymbolIds.split(",")

                if symbolIds.length<@slotGame.stripGroup.reels then throw "SymbolWindow.setSymbolsByRow: bad symbols length "+commaDelimSymbolIds

                for i in [1..@slotGame.stripGroup.reels]

                        @window[i][rowId]=symbolIds[i-1]



        setSymbolsByReelStop: (reelId,stop)->

                commaDelimSymbolIds = @slotGame.stripGroup.getSymbolsByStop(reelId,stop,@slotGame.stripGroup.rows).toString()

                @setSymbolsByReel(reelId,commaDelimSymbolIds)

        

        getSymbolsByRow: (rowId)->

                arr = []

                for i in [1..@slotGame.stripGroup.reels]

                        arr.push @window[i][rowId]

                return arr



        setAllSymbols: (commaDelimSymbolIds)-> #Go across reels in sequence

                symbolIds = commaDelimSymbolIds.split(",")

                if symbolIds.length<@slotGame.stripGroup.reels*@slotGame.stripGroup.rows then throw "SymbolWindow.setSymbolsByWindow: bad symbols length "+commaDelimSymbolIds

                z = 0

                for i in [1..@slotGame.stripGroup.rows]

                        for j in [1..@slotGame.stripGroup.reels]

                                @window[j][i]=symbolIds[z]

                                z++



        getAllSymbols: ()-> #Go across reels in sequence

                arr = []

                for i in [1..@slotGame.stripGroup.rows]

                        for j in [1..@slotGame.stripGroup.reels]

                                arr.push @getSymbol(j,i)

                return arr

                                

        getAllSymbolLocations: ()-> #Go across reels in sequence

                arr = []

                for i in [1..@slotGame.stripGroup.rows]

                        for j in [1..@slotGame.stripGroup.reels]

                                arr.push @getSymbolLocation(j,i)

                return arr



        findSymbols: (symbolId,reelIdStart=1,reelIdEnd=@slotGame.stripGroup.reels) ->

                arr = []

                for i in [reelIdStart..reelIdEnd]

                        for j in [1..@slotGame.stripGroup.rows]

                                if @window[i][j]==symbolId

                                        arr.push new SymbolLocation(symbolId,i,j)

                return arr

                

        countSymbols: (symbolId,reelIdStart=1,reelIdEnd=@slotGame.stripGroup.reels) ->

                c = 0

                for i in [reelIdStart..reelIdEnd]

                        for j in [1..@slotGame.stripGroup.rows]

                                if @window[i][j]==symbolId then c++

                return c



        findSymbolsByType: (isWild,isScatter,reelIdStart=1,reelIdEnd=@slotGame.stripGroup.reels) ->

                arr = []

                for i in [reelIdStart..reelIdEnd]

                        for j in [1..@slotGame.stripGroup.rows]

                                if @window[i][j].wild==isWild and @window[i][j].scatter==isScatter

                                        arr.push new SymbolLocation(@window[i][j],i,j)

                return arr



        countSymbolsByType: (isWild,isScatter,reelIdStart=1,reelIdEnd=@slotGame.stripGroup.reels) ->

                c = 0

                for i in [reelIdStart..reelIdEnd]

                        for j in [1..@slotGame.stripGroup.rows]

                                if @window[i][j].wild==isWild and @window[i][j].scatter==isScatter then c++

                return c
