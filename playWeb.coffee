# This is the main entry point for playing strategies against each
# other on the Web.

compileAndPlay = (scripts, doneCallback, errorCallbacks) ->
  strategies = []
  for i in [0...scripts.length]
    try
      strategy = CoffeeScript.eval(scripts[i], {bare: yes})
      console.log(strategy)
      strategies.push(strategy)
    catch e
      return errorCallbacks[i](e)
  playGame(strategies, doneCallback)

makeStrategy = (changes) ->
  ai = new BasicAI()
  for key, value of changes
    ai[key] = value
  ai

playGame = (strategies, ret) ->
  ais = (makeStrategy(item) for item in strategies)
  state = new State().initialize(ais, tableaux.all)
  ret ?= state.log
  window.setZeroTimeout -> playStep(state, ret)

playStep = (state, ret) ->
  if state.gameIsOver()
    ret(state)
  else
    state.doPlay()
    window.setZeroTimeout -> playStep(state, ret)

this.compileAndPlay = compileAndPlay