# This is the main entry point for playing strategies against each
# other on the Web.
#
# Needs more documentation.

compileStrategies = (scripts, errorHandler) ->
  strategies = []
  usedNames = []
  for i in [0...scripts.length]
    try
      strategy = CoffeeScript.eval(scripts[i], {bare: yes})
      while strategy.name in usedNames
        strategy.name += "Clone"
      usedNames.push(strategy.name)
      strategies.push(strategy)
    catch e
      errorHandler(e)
      return null
  return strategies

makeStrategy = (changes) ->
  ai = new BasicAI()
  for key, value of changes
    ai[key] = value
  ai

playGame = (strategies, options, ret) ->
  ais = (makeStrategy(item) for item in strategies)
  
  # Take note of the player names, in order, while they're
  # still in this order.
  options.tracker.setPlayers(ai.name for ai in ais)
  options.grapher.setPlayers(ai.name for ai in ais)
  
  state = new State().setUpWithOptions(ais, options)
  ret ?= options.log

  until state.gameIsOver()
    try
      state.doPlay()
      if state.phase == 'buy' and (not state.extraturn) and options.grapher?
        options.grapher.recordMoney(state.current.ai.name, state.current.turnsTaken, state.current.coins)
      if state.phase == 'cleanup' and (not state.extraturn) and options.grapher?
        options.grapher.recordVP(state.current.ai.name, state.current.turnsTaken, state.current.getVP(state))
    catch err
      errorHandler = options.errorHandler ? (alert ? console.log)
      errorHandler(err.message)
      window.donePlaying()
      throw err
  ret(state)

this.compileStrategies = compileStrategies
this.playGame = playGame
