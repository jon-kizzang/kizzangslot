#Created by Tony Suriyathep on 2013.12.30, Modified by Phillip Dean on 2014.10.30
#Code to analyze and run a Line based slot game

common = require("../../include/common")
SlotGame = require("../data/SlotGame").SlotGame
SlotSession = require("../data/SlotSession").SlotSession
SymbolWindow = require("../data/SymbolWindow").SymbolWindow
Analyzer = require("../data/Analyzer").Analyzer
AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup


#==================================================================================================#
#Actual game

class exports.UnderseaWorld2Game extends SlotGame

  #"Constant" Represents the minimum number of results that should be seen in a bonus game before a pooper
  minBunusResults = 4
  
  #"Constants" For the different bonus values
  #From the Math XML "Numbers > 0 are multipliers, 0 is a spin of the wheel, -1 are pointers that are added, -2 is a pooper"
  spinValue = 0
  pointerValue = -1
  pooperValue = -2
  
  wheelWedges: []
  pickArray: []

  muralSymbols: []
  expandingWilds: []

  #Import extras for this type of game
  importGame: ($json)->
    super $json
    @pickSecsAdded = parseInt $json.pickSecsAdded[0]

    @wheelWedges = $json.wheelWedges[0].split ","
    @pickArray = $json.pickObjects[0].split ","

    for i in [0...$json.muralSymbols[0].symbol.length]
      @muralSymbols.push $json.muralSymbols[0].symbol[i].$

    for i in [0...$json.expandingWilds[0].symbol.length]
      @expandingWilds.push $json.expandingWilds[0].symbol[i].$


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

    #Expanding mural tiles
    expandMatch = session.window.window[3][2]
    expandedIndex = -1

    for i in [0...@muralSymbols.length]

      if expandMatch == @muralSymbols[i].id

          expandedIndex = i

          for j in [2..4]

            for k in [1..3]

              session.window.window[j][k] = expandMatch

    for i in [0...@expandingWilds.length]

      if expandMatch == @expandingWilds[i].id

        for j in [1..3]

          session.window.window[3][j] = expandMatch

    #Analyze
    analyzerResultGroup = new AnalyzerResultGroup session

    #Process wins
    analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

    #Process results
    analyzerResultGroup.process false

    #Check Bonus trigger
    checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,6
    if checkTriggers != null
      
      #Ensure that the pickArray does not include the pooper in the first number of elements defined by minBunusResults
      #First remove the poopers from the pick array
      pickArray = @pickArray.slice()
      pooperArray = []
      
      for i in [0...pickArray.length]
        
        if (parseInt(pickArray[i]) == pooperValue)
          
          pooperArray.push(pickArray.splice(i, 1))
          
      #Shuffle the pooper-less pickArray
      pickArray = common.shuffle pickArray
      
      #Add the poopers back into the pickArray
      for i in [0...pooperArray.length]
        
        pickArray.splice(Math.floor(Math.random()*(pickArray.length - minBunusResults)) + minBunusResults, 0, -2)
      
      picks = []

      #Go through the pick array to determine the spin results
      totalMult = 0
      pointArray = [1]
      gotPooper = false
      bonusScore = 0

      # Get multipliers and pointers
      for i in [0...pickArray.length]

        if parseInt(pickArray[i]) > spinValue

          picks[i] = pickArray[i] + "x"

          if !gotPooper

            totalMult += parseInt(picks[i])

        else if parseInt(pickArray[i]) == pointerValue

          if !gotPooper
            # Get a new pointer, making sure not to have a pointer that already exists
            duplicate = true
            while duplicate == true

              duplicate = false
              newPointer = Math.floor(Math.random()*@wheelWedges.length) + 1;

              for j in [0...pointArray.length]

                if pointArray[j] == newPointer

                  duplicate = true

            pointArray.push newPointer
            picks[i] = "pointer" + newPointer

          else

            picks[i] = "pointer"

        else if parseInt(pickArray[i]) == pooperValue

          gotPooper = true

      gotPooper = false

      for i in [0...pickArray.length]

        if parseInt(pickArray[i]) == spinValue

          if !gotPooper

            spinObj = self.bonusGameSpin(totalMult, pointArray)
            bonusScore += spinObj.score
            picks[i] = "freespin" + spinObj.offset

          else

            picks[i] = "freespin"

        else if parseInt(pickArray[i]) == pooperValue

          if !gotPooper

            spinObj = self.bonusGameSpin(totalMult, pointArray)
            bonusScore += spinObj.score
            picks[i] = "pooper" + spinObj.offset
            gotPooper = true

          else

            picks[i] = "pooper"

      #The scatter win receives the wins of the picks
      checkTriggers[0].pay += bonusScore

      #Process bonus results
      analyzerResultGroup.pay += bonusScore
      analyzerResultGroup.profit += bonusScore

      retObj = 
        wheel: @wheelWedges
        mods: picks
        bonusWin: bonusScore
        totalWin: analyzerResultGroup.pay

      session.bonusPick = retObj

    else
      session.bonusPick = null

    ###
    Convert the expanded tiles to their Mural versions if necessary
    ###

    if expandedIndex != -1

      for i in [2..4]

        for j in [1..3]

          session.window.window[i][j] = @muralSymbols[expandedIndex].into

    return {
      session: session
      analyzerResultGroup: analyzerResultGroup
    }

  bonusGameSpin: ($mult, $pointArr)->

    #Determine what wedge of the wheel was landed on
    wedgeOffset = Math.floor(Math.random()*@wheelWedges.length)
    score = 0
    for i in [0...$pointArr.length]

      #Offset the pointer position and find the value
      score += parseInt(@wheelWedges[(($pointArr[i] - 1) + wedgeOffset) % @wheelWedges.length]) * (if $mult then $mult else 1)

    return { offset: wedgeOffset + 1, score: score } #Add 1 because the first wedge is considered to be at index 1 by the client

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

    #Log a warning if the retry logic took more than 10ms
    operationLimit = 20
    operationTime = new Date().getTime() - checkTime
    if operationTime > operationLimit then console.warn "WARNING -UnderseaWorldGame: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

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
