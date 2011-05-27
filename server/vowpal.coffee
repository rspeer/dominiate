exec = require("child_process").exec
util = require("./util")

dict2vw = (dict) ->
  # Take a JavaScript key->value object, which I still call a "dict", and
  # express it as a string in the format VW expects.
  colonSeparated = ["#{key.replace(/[ ]/g, '_')}:#{value}" for key, value of dict]
  colonSeparated.join(' ')

featureString = (name, categories) ->
  namefix = name.replace(/[ ]/g, '_')
  catStrings = [category+' '+dict2vw(value) for category, value of categories]
  allCatString = catStrings.join('| ')
  return "0 1 #{namefix}|#{allCatString}"

maximizePrediction = (modelName, vwInput, responder) ->
  proc = exec "sh vowpal-pipe.sh #{modelname}", (error, stdout, stderr) ->
    if error?
      responder.fail {
        code: error
        error: stderr
        model: modelName
        input: vwInput
      }
    else
      lines = stdout.split('\n')
      choices = []
      for line in lines
        console.log(line)
        [scoreStr, name] = line.split(' ')
        score = parseFloat(scoreStr)
        choices.push [name, score]
      
      if choices.length is 0
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

