#Created by Tony Suriyathep on 2013.12.30, Modified by Phillip Dean on 2014.10.30 and by The Engine Company on 2015.05.21
#Code to analyze and run a Line based slot game

common = require("../../include/common")
SlotGame = require("../data/SlotGame").SlotGame
SlotSession = require("../data/SlotSession").SlotSession
SymbolWindow = require("../data/SymbolWindow").SymbolWindow
Analyzer = require("../data/Analyzer").Analyzer
AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup


#==================================================================================================#
#Actual game

class exports.OakInTheKitchenGame extends SlotGame
  pickArray: []
  
  MIN_CONDIMENTS = 7 #The minimum number of condiments for a single bonus game
  MAX_MODS = 25 #The maximum number of mods allowed in a bonus game

  #Import extras for this type of game
  importGame: ($json)->
    super $json
    @pickSecsAdded = parseInt $json.pickSecsAdded[0]

    #Generate the pick array
    @pickArray = []
    for i in [0...$json.itemGroupPayout[0].payout.length]

      for j in [0...$json.itemGroupPayout[0].payout[i].$.quantity]

        @pickArray.push $json.itemGroupPayout[0].payout[i].$

  #Create a new session for new players
  createState: ($spinsTotal,$secsTotal)->
    json =
      spinsLeft: $spinsTotal
      spinsTotal: $spinsTotal
      secsLeft: $secsTotal
      secsTotal: $secsTotal
      winTotal: 0
      bonusPick: null

    return json

  # Split spin function to check ez than
  analyzeResultSpin: (session) ->

    self = @

    #Analyze
    analyzerResultGroup = new AnalyzerResultGroup session

    #Process wins
    analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

    #Process results
    analyzerResultGroup.process false

    #Check Bonus trigger
    checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,6
    if checkTriggers != null
      
      #Get and save any poopers
      pickArray = @pickArray.slice();
      poopers = []
      for i in [0...pickArray.length]

        if (pickArray[i - poopers.length].type == "pooper") #Coffeescript is stupid

          poopers.push(pickArray.splice(i, 1)[0])
          
      pickArray = common.shuffle pickArray
      picks = []
      
      #Go through the pick array to determine the bonus results
      totalMult = 1
      bonusScore = 0
      
      condimentCount = 0;
      
      # Get the multiplier and score
      pooperAdded = false;
      for i in [0...25]
        
        #If we got to the last available roll, add a pooper
        if (i == MAX_MODS - 1)
          
          picks[i] = poopers[0].name
          
          break;
        
        picks[i] = pickArray[0].name
        
        bonusScore += parseInt(pickArray[0].value)

        #Do type specific stuff (points for condiments, and multiplier for sides)
        if (pickArray[0].type == "condiment")
          
          picks[i] += "_" + pickArray[0].value
          condimentCount++
        
        else if (pickArray[0].type == "side")
          
          totalMult++
          
        #Break when we get a pooper, we don't need to provide any more data!
        if pickArray[0].type == "pooper"

          break;
          
        pickArray.splice(0, 1);
        
        if (condimentCount == MIN_CONDIMENTS && !pooperAdded)
            
            #Once we get MIN_CONDIMENTS condiments, add the pooper to the pick array and re-shuffle
            pickArray = common.shuffle(pickArray.concat(poopers))
            
            pooperAdded = true;

      #Apply the multiplier
      bonusScore *= totalMult

      #The scatter win receives the wins of the picks
      checkTriggers[0].pay += bonusScore

      #Process bonus results
      analyzerResultGroup.pay += bonusScore
      analyzerResultGroup.profit += bonusScore

      retObj = 
        mods: picks
        bonusWin: bonusScore
        totalWin: analyzerResultGroup.pay

      session.bonusPick = retObj

    else
      session.bonusPick = null

    return {
      session: session
      analyzerResultGroup: analyzerResultGroup
    }

  spin: ($state, $request)->
    self = @
    session = new SlotSession this
    if $state then  session.importState $state

    #Spin reels, check for cheating
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

    if (session.bonusPick) #Only add time if we got a bonus pick
      session.secsTotal += @pickSecsAdded
      session.secsLeft += @pickSecsAdded

    #Log a warning if the retry logic took more than 20ms
    operationLimit = 20
    operationTime = new Date().getTime() - checkTime
    if operationTime > operationLimit then console.warn "WARNING -OakInTheKitchen: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

    #Add to player
    session.winTotal += analyzerResultGroup.pay
    session.spinsLeft--

    state = session.exportState()
    state.bonusPick = session.bonusPick
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
