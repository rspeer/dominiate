class Grapher
  constructor: () ->
    @players = []
    @turnCounts = {}
    @vpTotals = {}
    @moneyTotals = {}
  
  reset: ->
    @players = []
    @turnCounts = {}
    @vpTotals = {}
    @moneyTotals = {}
    $.plot $("#money-graph"), []
    $.plot $("#vp-graph"), []
  
  setPlayers: (players) ->
    if players.join() != @players.join()
      this.reset()
      @players = players
  
  recordMoney: (player, turn, money) ->
    @moneyTotals[player] ?= [0]
    @turnCounts[player] ?= []
    @turnCounts[player][turn] ?= 0
    @turnCounts[player][turn]++
    @moneyTotals[player][turn] ?= 0
    @moneyTotals[player][turn] += money
  
  recordVP: (player, turn, vp) ->
    @vpTotals[player] ?= [3]
    @vpTotals[player][turn] ?= 0
    @vpTotals[player][turn] += vp

  # Assumes there are two players.
  updateGraphs: ->
    moneySeries = []
    vpSeries = []
    for player in @players
      money = []
      vp = []
      for turn in [1..30]
        @turnCounts[player] ?= []
        if @turnCounts[player][turn] ? 0 > 0
          money.push([turn, (@moneyTotals[player][turn] ? 0) / @turnCounts[player][turn]])
          vp.push([turn, (@vpTotals[player][turn] ? 0) / @turnCounts[player][turn]])
      moneySeries.push({label: player, data: money})
      vpSeries.push({label: player, data: vp})
    
    # Hack things so the first player is red, not yellow.
    moneySeries[0].color = 2
    moneySeries[1].color = 1
    vpSeries[0].color = 2
    vpSeries[1].color = 1
    
    $.plot $("#money-graph"), moneySeries, {
      series: {
        lines: {show: true}
        points: {show: true}
      }
      xaxis: {min: 0, max: 30}
      yaxis: {min: 0}
      legend: {position: 'nw'}
    }      
    $.plot $("#vp-graph"), vpSeries, {
      series: {
        lines: {show: true}
        points: {show: true}
      }
      xaxis: {min: 0, max: 30}
      yaxis: {min: 0}
      legend: {position: 'nw'}
    }      

this.Grapher = Grapher
