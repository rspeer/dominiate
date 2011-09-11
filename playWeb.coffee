# This is the main entry point for playing strategies against each
# other on the Web.
#
# Needs more documentation.

compileStrategies = (scripts, errorCallbacks) ->
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
      errorCallbacks[i](e)
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
  window.tracker.setPlayers(ai.name for ai in ais)
  
  # Handle options from the checkboxes on the page.
  if options.colonies
    tableau = tableaux.all
  else
    tableau = tableaux.noColony
  if options.randomizeOrder
    shuffle(ais)
  
  state = new State().initialize(ais, tableau, options.log)
  ret ?= options.log
  window.setZeroTimeout -> playStep(state, ret)

playStep = (state, ret) ->
  if state.gameIsOver()
    ret(state)
  else
    state.doPlay()
    window.setZeroTimeout -> playStep(state, ret)

this.compileStrategies = compileStrategies
this.playGame = playGame
