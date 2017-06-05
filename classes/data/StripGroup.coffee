Strip = require("./Strip").Strip





#==================================================================================================#

#Set of reelstrips for base, feature





class exports.StripGroup





        id: null #Group such as base, feature

        strips: null #Array of ReelStrip in reelId order

        reels: 0

        rows: 0





        constructor: (@id,strips)->

                if strips then @strips = strips





        getStrip: (reelId)-> return @strips[reelId-1]

        getRandomStop: (reelId)-> return @getStrip(reelId).getRandomStop()

        getRandomSymbol: (reelId)-> return @getStrip(reelId).getRandomSymbol()

        getSymbol: (reelId,stop)-> return @getStrip(reelId).getSymbol(stop)

        getLength: (reelId)-> return @getStrip(reelId).getLength()

        getSymbolsByStop: (reelId,stop,rowCount)-> return @getStrip(reelId).getSymbols(stop,rowCount)

        findStopBySymbol: (reelId,symbolId)-> return @getStrip(reelId).findStopBySymbol(symbolId)

        findStopBySymbols: (reelId,commaDelimSymbolIds)-> return @getStrip(reelId).findStopBySymbols(commaDelimSymbolIds)





        #Import single lineGroup

        @importFromXml: (json)->

                stripGroup = new StripGroup(json.$.id)

                stripGroup.reels = parseInt json.$.reels

                stripGroup.rows = parseInt json.$.rows



                #Import strips

                reelId = 1

                stripGroup.strips = []

                for strip in json.strip

                        stripGroup.strips.push Strip.importFromXml reelId,strip

                        reelId++



                return stripGroup
 
