#Created by Phillip Dean on 2014.10.20
#Code to analyze and run a Line based slot game
#James took over, oh no!
common = require("../../include/common")
SlotGame = require("../data/SlotGame").SlotGame
SlotSession = require("../data/SlotSession").SlotSession
SymbolWindow = require("../data/SymbolWindow").SymbolWindow
Analyzer = require("../data/Analyzer").Analyzer
AnalyzerResultGroup = require("../data/AnalyzerResultGroup").AnalyzerResultGroup


#==================================================================================================#
#Actual game

class exports.RomancingRichesGame extends SlotGame
  fsSpinsTotal: 0
  fsMxTotal: 0
  fsSecsAdded: 0

  #Import extras for this type of game
  importGame: ($json)->
    super $json
    @fsSpinsTotal = parseInt $json.fsSpinsTotal[0]
    @fsMxTotal = parseInt $json.fsMxTotal[0]
    @fsSecsAdded = parseInt $json.fsSecsAdded[0]


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
    return json

  # Split spin function to check ez than
  analyzeResultSpin: (session) ->
    #Analyze
    analyzerResultGroup = new AnalyzerResultGroup session

    if session.fsOn
      analyzerResultGroup.add Analyzer.calculate(session,this.reels,session.fsMxTotal,true,true)

      #Process results
      analyzerResultGroup.process true

    else
      analyzerResultGroup.add Analyzer.calculate(session,this.reels,1,true,true)

      #Process results
      analyzerResultGroup.process false

    return {
      session: session
      analyzerResultGroup: analyzerResultGroup
    }

  checkFS: ($analyzer, $session)->

    analyzerResultGroup = $analyzer

    session = $session

    if session.fsOn
      session.fsSpinsLeft--

      #Check triggers
      checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3
      if checkTriggers != null and session.fsSpinsLeft <= 0
        session.fsOn = true
        session.spinsTotal += @fsSpinsTotal
        session.spinsLeft += @fsSpinsTotal
        session.fsSpinsLeft += @fsSpinsTotal
        session.fsSpinsTotal += @fsSpinsTotal
        session.fsMxTotal = @fsMxTotal
        session.secsTotal += @fsSecsAdded
        session.secsLeft += @fsSecsAdded
        session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded}
        checkTriggers[0].trigger = 'trigger'

      #Track free spins
      session.fsWinTotal += analyzerResultGroup.pay
      if session.fsSpinsLeft<0
        session.fsOn = false
        session.fsSpinsLeft = 0
        session.fsSpinsTotal = 0
        session.fsMxTotal = 0
        session.fsWinTotal = 0

    #Base games
    else
      #Check B trigger
      checkTriggers = analyzerResultGroup.findSymbolWins 'B',3,3

      if checkTriggers != null
        session.fsOn = true
        session.spinsTotal += @fsSpinsTotal
        session.spinsLeft += @fsSpinsTotal
        session.fsSpinsLeft += @fsSpinsTotal
        session.fsSpinsTotal += @fsSpinsTotal
        session.fsMxTotal = @fsMxTotal
        session.secsTotal += @fsSecsAdded
        session.secsLeft += @fsSecsAdded
        session.fsTrigger = {name:'trigger',spins:@fsSpinsTotal,secs:@fsSecsAdded}
        checkTriggers[0].trigger = 'trigger'
		
  spin: ($state, $request)->
    
    self = @
    session = new SlotSession this
    if $state then  session.importState $state

    ###
    If we are in a bonus state, we want to use the bonus reel
    ###
    json = session.window.slotGame.configuration.stripGroup

    if not $state or $state.fsOn == false
        session.window.slotGame.importStripGroup json, "base"
    else
        session.window.slotGame.importStripGroup json, "bonus"

    #Spin reels, check for cheating
    spinArr = null

    # Loop till condition is pass
    analyze = null

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

    #Log a warning if the retry logic took more than 10ms
    operationLimit = 10
    operationTime = new Date().getTime() - checkTime
    if operationTime > operationLimit then console.warn "WARNING -RomancingRichesGame: Respin took more than " + operationLimit + "ms. Operation took " + operationTime + "ms over " + i + " spins"

	
	
    #Handle free spin state
    self.checkFS analyze.analyzerResultGroup, analyze.session

    #Add to player
    session.winTotal += analyzerResultGroup.pay
    session.spinsLeft--

    #Respond!
    obj=
      state: session.exportState()
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
