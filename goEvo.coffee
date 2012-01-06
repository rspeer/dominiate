
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
coffee = require 'coffee-script'

namer = (num) ->
        ret = ''
        onset = ['b','bl','br','ch','d','dr','dw','f','fl','fr','g','gl','gr','gw','h','j','k','kl','kr','l','m','n','p','q','r','s','schm','schn','scl','scr','sh','shl','shr','sht','sk','sl','sm','sn','sp','spl','spr','st','sw','sy','t','th','thr','thw','tr','tw','v','w','y','z']
        r = ['a','e','ea','i','i','o','oa','oi','oo','ou','u']
        coda = ['b','ch','d','f','g','h','j','k','l','m','n','ng','p','r','s','sh','t','th','v','w','y','z']             
        
        onset.sort()
        r.sort()
        coda.sort()
        
        ret += onset[num%onset.length]
        num = Math.floor(num/onset.length)
        ret += r[num%r.length]
        num = Math.floor(num/r.length)
        ret += coda[num%coda.length]
        num = Math.floor(num/coda.length)
        
        while num > 0
                ret += "-"
                
                ret += onset[num%onset.length]
                num = Math.floor(num/onset.length)
                ret += r[num%r.length]
                num = Math.floor(num/r.length)
                ret += coda[num%coda.length]
                num = Math.floor(num/coda.length)
        return ret

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
  
get3DistinctRandos = (ais) ->
        picked = []
        while picked.length < 3
                rand = Math.floor(Math.random()*ais.length)
                picked.push(ais[rand])
                ais.splice(rand,1)
        picked
        
minin = (arr) ->
        min = arr[0]
        minIndex = 0
        for a in [0...arr.length]
               if arr[a] < min
                       min = arr[a]
                       minIndex = a               
        minIndex

goEvo = (action = 'start', directory = 'test', firstGen = 3, gamesPerMatch = 1) ->
        fullTimer = new TicToc()
        fullTimer.tic()
        console.log("Load Players")
        filename = directory+"/currentGeneration.evo"
        if action == 'start'
                nameNum = 0
                try fs.mkdirSync(directory)
                filenames = fs.readdirSync(directory)
                fs.unlinkSync(directory+"/"+f) for f in filenames
                evos = (new EvoAI(namer(nameNum++)) for num in [0...firstGen])
                fs.writeFileSync(directory+"/"+evo.name+".coffee",evo.toString()) for evo in evos
                numGames = 0
                genNum = 0
        else if action == 'continue'
                savedObject = JSON.parse(fs.readFileSync(filename, 'utf-8'))
                evos = (new EvoAI(no).unpickle(evo) for evo in savedObject["evos"])
                gamesPerMatch = savedObject["gamesPerMatch"]
                nameNum = savedObject["namerSeed"]
                genNum = savedObject["generationNumber"]
                firstGen = evos.length
                numGames = 0
        else
                console.log("not a valid action. Try 'start' or 'continue'");
                return
        console.log("Done Load Players")
        while true
                numGames = 0
                while numGames < firstGen
                        numGames++
                        players = get3DistinctRandos(evos)
                        results = [0,0,0]      
                        matches = [[0,1],[0,2],[1,2]]        
                        for match in matches 
                                defender = loadStrategy(players[match[0]].toString())
                                chalenger = loadStrategy(players[match[1]].toString())
                                console.log()
                                console.log("Match "+numGames+" of "+firstGen)
                                console.log(defender.name+"("+defender.parents+")"+" Vs. "+chalenger.name+"("+chalenger.parents+")")
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
                                        catch error
                                                console.log(error)
                                        finally
                                                sys.print(".") if tnum % 100 == 0
                                console.log(defender.name+" "+dw+" Wins; "+chalenger.name+" "+cw+" Wins; "+t+" Ties")
                                results[match[0]] += dw
                                results[match[1]] += cw
                        console.log()
                        console.log("Round Robbin Results")
                        outStr = ""
                        outStr += players[z].name+" : "+results[z]+" Wins " for z in [0...results.length]
                        console.log(outStr)
                        console.log()
                        loser = minin(results)
                        console.log(players[loser].name+" Dies")
                        players.splice(loser,1)
                        evos.push(players[0])
                        evos.push(players[1])
                        evos.push(players[0].mate(players[1],namer(nameNum++)))
                        console.log(players[0].name+" and "+players[1].name+" have child "+evos[evos.length-1].name)
                genNum++
                console.log("Recording All Players")
                fs.writeFileSync(directory+"/"+evo.name+".coffee",evo.toString()) for evo in evos
                console.log("Execution Took "+fullTimer.tocString())
                try fs.renameSync(filename,directory+"/generation"+(genNum-1)+".evo")
                fs.writeFileSync(filename,JSON.stringify({"evos":evos,"generationNumber":genNum,"namerSeed":nameNum,"gamesPerMatch":gamesPerMatch}))

this.playGame = playGame
action = process.argv[2]
fileName = process.argv[3]
numInFirstGen = process.argv[4]
gamesPerMatch = process.argv[5]
logFile = fs.createWriteStream(fileName+"-goEvo.log");

logFile.once('open', (fd)->
  goEvo(action,fileName,numInFirstGen,gamesPerMatch))

exports.loadStrategy = loadStrategy
exports.playGame = playGame

fileLogger = (s) ->
        return
	#logFile.write(s+"\r\n")
	
