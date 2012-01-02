#!/usr/bin/env coffee
#
# This is the script that you can run at the command line to see how
# strategies play against each other.

{State,tableaux} = require './gameState'
{BasicAI} = require './basicAI'
{TicToc} = require './tictoc.js'
{EvoAI} = require './evolutionAI'
fs = require 'fs'
sys = require 'util'
coffee = require '/Program Files (x86)/nodejs/node_modules/coffee-script/lib/coffee-script'
logFile = fs.createWriteStream("evaluate.log");

loadStrategy = (body) ->
  ai = new BasicAI()
  contents = coffee.compile(
    body,
    {bare: yes}
  )
  str = contents
  contents = contents.replace("return[ [","return[")
  contents = contents.replace("]];","];")
  
  changes = eval(contents)

  for key, value of changes
    ai[key] = value
  ai

playGame = (ais, numGames = 1) ->
  #ais = (loadStrategy(filename) for filename in filenames)
  st = new State().setUpWithOptions(ais, {
    colonies: false
    randomizeOrder: true
    log: fileLogger
    require: []
  })
  until st.gameIsOver()
    st.doPlay()
  result = ([player.ai.toString(), player.getVP(st), player.turnsTaken] for player in st.players)
  st.getWinners()
  
playTourney = (dir = "./strategies", gamesPerMatch = 1) ->
  filenames = fs.readdirSync(dir)
  console.log("Load Players")
  savedObject = JSON.parse(fs.readFileSync(dir+"/currentGeneration.evo", 'utf-8'))
  genNum = savedObject["generationNumber"]
  evos = (new EvoAI(no).unpickle(evo) for evo in savedObject["evos"])             
  ais = (loadStrategy(evo.toString()) for evo in evos)
  results = {}
  vsBigMoney = {}
  standings = new Array()
  fullTimer = new TicToc()
  fullTimer.tic()
  defender = loadStrategy(fs.readFileSync("strategies/BigMoney.coffee", 'utf-8'))
  numGames = 0
  console.log("Players Loaded")
  for ai in ais
        numGames++
        console.log("Match "+numGames+" of "+(ais.length))
        chalenger = ai
        dw = 0
        cw = 0
        t = 0
        tnum = 0
        while tnum < gamesPerMatch
                
                try
                        result = playGame([defender,chalenger])
                        if result.length > 1
                                t++
                        else if defender.name in result
                                dw++
                        else if chalenger.name in result
                                cw++
                        else
                                console.warn("Something is wrong")
                tnum++
                sys.print(".") if tnum % 10 == 0
        console.log(defender.name+" "+dw+" Wins; "+chalenger.name+" "+cw+" Wins; "+t+" Ties")
        vsBigMoney = cw/gamesPerMatch*100
        console.log(chalenger.name+" vs BigMoney: "+vsBigMoney+"% Win Rate")
        inserted = false
        for num in [0...standings.length]
                if vsBigMoney >= standings[num].result
                        standings.splice(num,0,{name:chalenger.name, result:vsBigMoney})
                        inserted = true
                        break
        if !inserted
                standings.push({name:chalenger.name, result:vsBigMoney})
  html = "<h1>Standngs after "+genNum+" generations</h1>"
  html+="#"+(num+1)+": <a href='"+standings[num].name+".coffee'>"+standings[num].name+"</a> "+standings[num].result+"% Vs BigMoney<br>" for num in [0...standings.length]
  fs.writeFileSync(dir+"/index.html",html)
  console.log("Execution Took "+fullTimer.tocString())
  
this.playGame = playGame
dir = process.argv[2]
gamesPerMatch = process.argv[3]
logFile.once('open', (fd)->
  logFile.write("Game Start\r\n")
  playTourney(dir,gamesPerMatch))

exports.loadStrategy = loadStrategy
exports.playGame = playGame

fileLogger = (s) ->
        return
	#logFile.write(s+"\r\n")
	
