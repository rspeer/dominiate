

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


playTourney = (action,dir = "./strategies",webdir = "~/html/dominiate/strategies", gamesPerMatch = 100,firstGen = 1000) ->
        fullTimer = new TicToc()
        fullTimer.tic()
        console.log("Load Players")
        filename = dir+"/currentGeneration.evo"
        if action == 'start'
                nameNum = 0
                try fs.mkdirSync(dir)
                filenames = fs.readdirSync(dir)
                fs.unlinkSync(dir+"/"+f) for f in filenames
                evos = (new EvoAI(namer(nameNum++)) for num in [0...firstGen])
                #fs.writeFileSync(directory+"/"+evo.name+".coffee",evo.toString()) for evo in evos
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
                
        while genNum < 1000
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
                                      standings.splice(num,0,{name:chalenger.name, result:vsBigMoney,ref:(numGames-1)})
                                      inserted = true
                                      break
                      if !inserted
                              standings.push({name:chalenger.name, result:vsBigMoney,ref:(numGames-1)})
                      html = "<h1>Standngs after "+genNum+" generations</h1>"
                      html += "<p>"+(new Date()).toString()+"</p>"
                      html += "<p><a href=standings.txt>multi generation report (csv)</a></p>"
                      html+="#"+(num+1)+": <a href='"+standings[num].name+".coffee'>"+standings[num].name+"</a> "+standings[num].result+"% Vs BigMoney<br>" for num in [0...standings.length]
                      fs.writeFileSync(dir+"/generaton"+genNum+".standings",JSON.stringify(standings))
                      try fs.mkdirSync(webdir)
                      filenames = fs.readdirSync(webdir)
                      fs.unlinkSync(webdir+"/"+f) for f in filenames when f.search('.coffee') isnt -1
                      fs.writeFileSync(webdir+"/"+ai.name+".coffee",ai.toString()) for ai in evos
                      fs.writeFileSync(webdir+"/index.html",html)
                
                ptr = Math.floor(evos.length/3)*2
                while ptr < evos.length
                        r1 = Math.floor(Math.random()*evos.length/3)
                        r2 = Math.floor(Math.random()*evos.length/3)
                        mom = evos[standings[r1].ref]
                        dad = evos[standings[r2].ref]
                        evos[ptr] = mom.mate(dad,namer(nameNum++))
                        console.log(mom.name+" and "+dad.name+" have child "+evos[ptr].name+" replacing rank #"+ptr)
                        ptr++                     
                fs.writeFileSync(filename,JSON.stringify({"evos":evos,"generationNumber":genNum,"namerSeed":nameNum,"gamesPerMatch":gamesPerMatch}))
                genNum++
                createCSV(dir,webdir+"/standings.txt")
        console.log("Execution Took "+fullTimer.tocString())
  
createCSV = (sourceDir,destFile) ->
        filenames = fs.readdirSync(sourceDir)
        csvStr = "GenNum,Min,Max,Mean,Median,Mode\n"
        csvArray = new Array()
        keys = new Array()
        for f in filenames when f.search('.standings') isnt -1
            genNum = /\d+/.exec(f)[0]
            standings = JSON.parse(fs.readFileSync(sourceDir+"/"+f, 'utf-8'))
            min = standings[0]["result"]
            max = standings[0]["result"]
            mean = 0
            median = 0
            mode = 0
            for st in standings
                        min = st["result"] if st["result"] < min
                        max = st["result"] if st["result"] > max
                        mean += st["result"]
            mean /= standings.length
            keys.push(genNum)
            csvArray[genNum] = [genNum,min,max,mean,median,mode].join(",")+"\n"
        keys.sort((a, b)->(a - b))
        csvStr += csvArray[k] for k in keys
        fs.writeFileSync(destFile,csvStr)
        
this.playGame = playGame
action = process.argv[2]
sourcedir = process.argv[3]
webdir = "../html/dominiate/"
#webdir = ""
seedpop = process.argv[4]
gamesPerMatch = process.argv[5]
logFile = fs.createWriteStream(sourcedir+"-bigEvo.log");
logFile.once('open', (fd)->
  logFile.write("Game Start\r\n")
  playTourney(action,sourcedir,webdir+sourcedir,gamesPerMatch,seedpop)
  createCSV(sourcedir,webdir+sourcedir+"/standings.txt")
  )

exports.loadStrategy = loadStrategy
exports.playGame = playGame

fileLogger = (s) ->
        return
