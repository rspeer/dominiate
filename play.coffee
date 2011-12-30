#!/usr/bin/env coffee
#
# This is the script that you can run at the command line to see how
# strategies play against each other.

{State,tableaux} = require './gameState'
{BasicAI} = require './basicAI'
fs = require 'fs'
coffee = require '/Program Files (x86)/nodejs/node_modules/coffee-script/lib/coffee-script'

loadStrategy = (filename) ->
  ai = new BasicAI()
  console.log(filename)

  changes = eval coffee.compile(
    fs.readFileSync(filename, 'utf-8'),
    {bare: yes}
  )
  for key, value of changes
    ai[key] = value
  ai

playGame = (filenames) ->
  ais = (loadStrategy(filename) for filename in filenames)
  st = new State().setUpWithOptions(ais, {
    colonies: false
    randomizeOrder: true
    log: console.log
    require: []
  })
  until st.gameIsOver()
    st.doPlay()
  result = ([player.ai.toString(), player.getVP(st), player.turnsTaken] for player in st.players)
  console.log(result)
  result

this.playGame = playGame
console.log("HELLO")
console.log(process.argv[2])
console.log(process.argv[3])
args = process.argv[2...]
playGame(args)

exports.loadStrategy = loadStrategy
exports.playGame = playGame
