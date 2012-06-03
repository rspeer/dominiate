# This isn't a standalone file that can be run with the "coffee" interpreter.
# It's a unit test file.
# 
# You can run it through "nodeunit" (`npm install nodeunit`), which now has
# built-in support for CoffeeScript:
#
#     nodeunit testSimulation.coffee

c = require('./cards')
gameState = require('./gameState')
basicAI = require('./basicAI')
{loadStrategy} = require('./play')

this['game is initialized correctly'] = (test) ->
  ai1 = new basicAI.BasicAI()
  ai2 = new basicAI.BasicAI() 
  st = new gameState.State().initialize([ai1, ai2], gameState.tableaux.moneyOnly)
  test.equal st.players.length, 2 
  test.equal st.current.getVP(), 3
  test.equal st.current.hand.length, 5
  test.equal st.current.draw.length, 5
  test.equal st.current.discard.length, 0
  test.equal st.current.getDeck().length, 10
  test.equal st.phase, 'start'
  test.equal st.gameIsOver(), false
  test.done()

this['game phases proceed as expected'] = (test) ->
  ai1 = new basicAI.BasicAI()
  ai2 = new basicAI.BasicAI()
  st = new gameState.State().setUpWithOptions([ai1, ai2], {})
  st.doPlay(); test.equal st.phase, 'action'
  st.doPlay(); test.equal st.phase, 'treasure'
  st.doPlay(); test.equal st.phase, 'buy'
  st.doPlay(); test.equal st.phase, 'cleanup'
  st.doPlay(); test.equal st.phase, 'start'
  st.doPlay(); test.equal st.phase, 'action'
  st.doPlay(); test.equal st.phase, 'treasure'
  st.doPlay(); test.equal st.phase, 'buy'
  st.doPlay(); test.equal st.phase, 'cleanup'
  st.doPlay(); test.equal st.phase, 'start'
  st.doPlay(); test.equal st.phase, 'action'
  st.doPlay(); test.equal st.phase, 'treasure'
  st.doPlay(); test.equal st.phase, 'buy'
  st.doPlay(); test.equal st.phase, 'cleanup'
  until st.gameIsOver()
    st.doPlay()
  console.log([player.ai.toString(), player.getVP(st), player.turnsTaken] for player in st.players)
  test.done()

this['2-player smoke test'] = (test) ->
  ais = (loadStrategy('strategies/SillyAI.coffee') for i in [1..2])
  noLog = (message) ->
  for i in [0...100]
    st = new gameState.State().setUpWithOptions(ais, {log: console.warn, require: []})
    until st.gameIsOver()
      st.doPlay()
  test.done()
