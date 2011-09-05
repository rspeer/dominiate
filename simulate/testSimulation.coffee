c = require('./cards')
gameState = require('./gameState')
BasicAI = require('./basicAI').BasicAI

this['game is initialized correctly'] = (test) ->
  st = new gameState.State().initialize([null, null], gameState.supplies.money2P)
  test.equal st.players.length, 2 
  test.equal st.current.getVP(), 3
  test.equal st.current.hand.length, 5
  test.equal st.current.draw.length, 5
  test.equal st.current.discard.length, 0
  test.equal st.current.getDeck().length, 10
  test.equal st.phase, 'start'
  test.equal st.gameIsOver(), false
  test.done()

this['AI resolves decisions on first three turns'] = (test) ->
  ai = new BasicAI()
  st = new gameState.State().initialize([ai], gameState.supplies.money2P)
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
  test.done()
