class ScoreTracker
  constructor: (@scoreElt) ->
    @games = 0
    @players = []
    @scores = []
  
  reset: ->
    @games = 0
    @players = []
    @scores = []
    @proportions = []
  
  setPlayers: (players) ->
    if players.join() != @players.join()
      this.reset()
      @players = players
      @scores = (0 for player in @players)
      @proportions = (0 for player in @players)

  incrementPlayerScore: (player, inc) ->
    for i in [0...@players.length]
      if @players[i] == player
        @scores[i] += inc
        break
  
  getPlayerScore: (player) ->
    for i in [0...@players.length]
      if @players[i] == player
        return @scores[i]

  recordGame: (state) =>
    if state.gameIsOver()
      winners = state.getWinners()
      for winner in winners
        this.incrementPlayerScore(winner, 1.0 / winners.length)
      @games += 1
      this.updateScores()

  errorMargin: ->
    1.5 / Math.sqrt(@games)

  updateScores: ->
    @proportions = (score / @games for score in @scores)
    if @scoreElt?
      this.updateScoresOnPage()
  
  decisiveWinner: ->
    for i in [0...@players.length]
      if @proportions[i] - this.errorMargin() > 1 / @scores.length
        return @players[i]
    return null

  updateScoresOnPage: ->
    pieces = []
    for i in [0...@players.length]
      pieces.push("""<div>
        <span class="player#{i+1}">#{@players[i]}</span>:
        #{@scores[i]} wins (#{roundPercentage(@proportions[i])}%)
      </div>""")
    @scoreElt.html(pieces.join(''))

roundPercentage = (num) ->
  (num * 100).toFixed(1)

this.ScoreTracker = ScoreTracker
