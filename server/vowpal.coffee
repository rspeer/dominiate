spawn = require("child_process").spawn
util = require("./util")

MODELPATH = __dirname + "/../model"

dict2vw = (dict) ->
  # Take a JavaScript key->value object, which I still call a "dict", and
  # express it as a string in the format VW expects.
  colonSeparated = ["#{key.replace(/[ ]/g, '_')}:#{value}" for key, value of dict]
  return colonSeparated.join().replace(/,/g, ' ').replace(/NaN/g, '0')

featureString = (name, categories) ->
  namefix = JSON.stringify(name).replace(/[ ]/g, '_')
  catStrings = [category+' '+dict2vw(value) for category, value of categories]
  allCatString = catStrings.join().replace(/,/g, ' |')
  return "0 1 #{namefix}|#{allCatString}"

maximizePrediction = (modelName, vwInput, responder) ->
  proc = spawn('sh', ['vowpal-pipe.sh', "#{MODELPATH}/#{modelName}"])
  proc.stdin.setEncoding('utf8')
  proc.stdout.setEncoding('utf8')
  received = []
  proc.stdout.on 'data', (data) ->
    received.push(data)
  proc.stderr.on 'data', (data) ->
    console.log('stderr: '+data)
  proc.on 'exit', (code) ->
    if code
      responder.fail {
        errorCode: code
        model: modelName
        input: vwInput
      }
    else
      lines = received.join('').split('\n')
      choices = []
      for line in lines
        if line
          [scoreStr, name] = line.split(' ')
          name = JSON.parse(name.replace(/_/g, ' '))
          score = parseFloat(scoreStr)
          choices.push [name, score]
      
      if choices.length == 0
        responder.fail {
          error: 'no choices given'
          model: modelName
          input: vwInput
        }

      # Sort the choices in descending order by score.
      choices.sort (a, b) ->
        b[1] - a[1]
      responder.succeed {
        choices: choices
        best: choices[0][0]
        score: choices[0][1]
      }
  proc.stdin.write(vwInput)
  proc.stdin.end()

exports.dict2vw = dict2vw
exports.featureString = featureString
exports.maximizePrediction = maximizePrediction
