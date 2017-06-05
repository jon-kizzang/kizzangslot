#Created by Tony James Harding on 2013.12.30
#Code to analyze and run a Line based slot game

common = require("../../include/common")
SlotGame = require("../data/SlotGame").SlotGame
SlotSession = require("../data/SlotSession").SlotSession
SymbolWindow = require("../data/SymbolWindow").SymbolWindow
Analyzer = require("../data/Analyzer").Analyzer
AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup


#==================================================================================================#
#Actual game

class exports.PaymentPanicGame extends SlotGame
  pickBandits: null
  pickBags: null
  pickSecsAdded: 0
  maxBonusGameHits: 0

  #Import extras for this type of game
  importGame: ($json)->
    super $json
    @pickSecsAdded = parseInt $json.pickSecsAdded[0]

    @pickBandits = $json.pickBandits[0].split ','
    for i in [0 .. @pickBandits.length-1]
      @pickBandits[i] = parseInt @pickBandits[i]

    @pickBags = $json.pickBags[0].split ','
    for i in [0 .. @pickBags.length-1]
      @pickBags[i] = parseInt @pickBags[i]
    
    @maxBonusGameHits = parseInt $json.maxBonusGamesHits[0]


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

  calculateBonuses:(session) ->
    column = session.window.window.length-1
    row = session.window.window[column].length-1
    return session.window.window[column][row]

  # Split spin function to check ez than
  analyzeResultSpin: (session) ->

    #Analyze
    analyzerResultGroup = new AnalyzerResultGroup session
    analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

    #Process results
    analyzerResultGroup.process false
    
    session.pickBonus = null
    
    #Check trigger
    checkTriggers = @calculateBonuses session#analyzerResultGroup.findSymbolWins 'B',3,6
    #console.log "Check Triggers: " + checkTriggers
    if checkTriggers == 'B'
      session = @createPickBonus(session)
      #console.log "Pick Bonus: " + JSON.stringify(session.pickBonus)
      #The scatter win receives the wins of the picks
      checkTriggers[0].trigger = 'trigger'
      checkTriggers[0].pay += session.pickBonus.total

      #Process results
      analyzerResultGroup.pay += session.pickBonus.total
      #console.log "pickbonuswin: " + session.pickBonus.total
      #console.log "Pay: " + analyzerResultGroup.pay
    else if checkTriggers.indexOf("Px") >= 0
      #This is a multiplier win
      #console.log "CheckTriggers: " + checkTriggers.length
      multiplierVal = parseInt(checkTriggers.substring(checkTriggers.length-1))
      if(multiplierVal <= 0)
        multiplierVal = 1
      analyzerResultGroup.pay *= multiplierVal
      #console.log "Multiplier Val: " + multiplierVal
    #No bonus
    else if checkTriggers.indexOf("Pd") >= 0
      #this is no win spin
      analyzerResultGroup.pay = 0
      #console.log "Pay is Zero"
    else
      session.pickBonus = null

    return {
      session: session
      analyzerResultGroup: analyzerResultGroup
    }

  createPickBonus: (session)->
    #Run bandit, fake the other 2
    bandits = []
    mx = parseInt(@probabilityGroup.run('pickBandit'))
    if mx == 2
      bandits.push 3
      bandits.push 5
    else if mx == 3
      bandits.push 2
      bandits.push 5
    else if mx == 5
      bandits.push 2
      bandits.push 3
    bandits = common.shuffle bandits
    bandits.unshift mx

    #Copy bags
    bags = []
    for i in [0 .. @pickBags.length-1]
      bags.push @pickBags[i]
    bags = common.shuffle bags

    #Reshuffle if losing index in first index
    while bags[0] == 0 || bags.indexOf(0) > 14
      #console.log "Pooper index: " + bags.indexOf(0)
      bags = common.shuffle bags
      

    #Update value of bags
    win = 0
    total = 0
    dontAdd = false
    for i in [0 .. @pickBags.length-1]
      if bags[i]==0 then dontAdd=true
      bags[i] = bags[i] * session.getTotalWager()
      if dontAdd==false
        win += bags[i]
        total += bags[i] * bandits[0]

    session.pickBonus = {bandits:bandits,bags:bags,win:win,total:total,secs:@pickSecsAdded}

    return session

  spin: ($state, $request)->
    
    self = @
    session = new SlotSession this
    if $state then  session.importState $state
    #console.log session

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

      checkTriggers = @calculateBonuses session
      #console.log "Check Trigger: " + checkTriggers
      result = self.checkConditionsRoll session, analyzerResultGroup
      if checkTriggers == "B"
        if  session.fsMxTotal < @maxBonusGameHits && session.spinsLeft > 1
          break if (result)
      else if(checkTriggers == "Pd")
          break
      else
        break if (result)
    
    checkTriggers = @calculateBonuses session
    if(checkTriggers == "B")
      console.log "Pick bonus: " + JSON.stringify(session.pickBonus)
    #Only add time if there is a pick bonus
    if session.pickBonus
      session.secsTotal += @pickSecsAdded
      session.secsLeft += @pickSecsAdded
      session.fsMxTotal++

    #Log a warning if the retry logic took more than 10ms
    operationLimit = 10
    operationTime = new Date().getTime() - checkTime
    if operationTime > operationLimit then console.warn "WARNING -BankrollBanditsGame: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

    #Add to player
    session.winTotal += analyzerResultGroup.pay
    session.spinsLeft--

    #Send state
    state = session.exportState()
    state.pickBonus = session.pickBonus
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
