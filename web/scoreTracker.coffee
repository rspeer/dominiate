class ScoreTracker
  constructor: (@scoreInHtml) ->
    @games = 0
    @players = []
    @scores = []
    @proportions = []
    @elementWidth = 940
  
  reset: ->
    @games = 0
    @players = []
    @scores = []
    @proportions = []
    if @scoreInHtml
      this.updateScoresOnPage()
  
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
    winners = state.getWinners()
    for winner in winners
      this.incrementPlayerScore(winner, 1.0 / winners.length)
    @games += 1
    this.updateScores()

  errorMargin: ->
    # three standard deviations according to Z-score
    1.5 / Math.sqrt(@games)

  updateScores: =>
    @proportions = (score / @games for score in @scores)
  
  # This should be using a binomial distribution, 
  # but N>=40 is probably Gaussian enough
  decisiveWinner: =>
    for i in [0...@players.length]
      if @proportions[i] - this.errorMargin() > 1 / @scores.length
        return @players[i]
    return null

  # Assumes there are two players.
  updateScoresOnPage: ->
    if @games == 0
      # If no games have been played, reset the boxes.
      $('#win-p1-certain').width(10)
      $('#win-p2-certain').width(10)
      $('#win-p1-uncertain').width(469)
      $('#win-p2-uncertain').width(469)
      $('#score-p1').html('')
      $('#score-p2').html('')
      return
    
    err = this.errorMargin()
    certain1 = @proportions[0] - err
    certain1 = 0 if certain1 < 0
    certain2 = @proportions[1] - err
    certain2 = 0 if certain2 < 0
    uncertain1 = @proportions[0]
    uncertain1 = 1 if uncertain1 > 1
    uncertain2 = @proportions[1]
    uncertain2 = 1 if uncertain2 > 1

    $('#win-p1-certain').width(@elementWidth * certain1)
    $('#win-p2-certain').width(@elementWidth * certain2)
    $('#win-p1-uncertain').width(@elementWidth * uncertain1 - 1)
    $('#win-p2-uncertain').width(@elementWidth * uncertain2 - 1)
    scoreHtml = [null, null]
    for i in [0..1]
      scoreHtml[i] = """<strong>#{@players[i]}</strong>:
        #{@scores[i]} wins (#{roundPercentage(@proportions[i])}%)"""
    $('#score-p1').html(scoreHtml[0])
    $('#score-p2').html(scoreHtml[1])

roundPercentage = (num) ->
  (num * 100).toFixed(1)

this.ScoreTracker = ScoreTracker
