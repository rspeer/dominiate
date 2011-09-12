(function() {
  var ScoreTracker, roundPercentage;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  ScoreTracker = (function() {
    function ScoreTracker(scoreElt) {
      this.scoreElt = scoreElt;
      this.decisiveWinner = __bind(this.decisiveWinner, this);
      this.updateScores = __bind(this.updateScores, this);
      this.recordGame = __bind(this.recordGame, this);
      this.games = 0;
      this.players = [];
      this.scores = [];
    }
    ScoreTracker.prototype.reset = function() {
      this.games = 0;
      this.players = [];
      this.scores = [];
      return this.proportions = [];
    };
    ScoreTracker.prototype.setPlayers = function(players) {
      var player;
      if (players.join() !== this.players.join()) {
        this.reset();
        this.players = players;
        this.scores = (function() {
          var _i, _len, _ref, _results;
          _ref = this.players;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            player = _ref[_i];
            _results.push(0);
          }
          return _results;
        }).call(this);
        return this.proportions = (function() {
          var _i, _len, _ref, _results;
          _ref = this.players;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            player = _ref[_i];
            _results.push(0);
          }
          return _results;
        }).call(this);
      }
    };
    ScoreTracker.prototype.incrementPlayerScore = function(player, inc) {
      var i, _ref, _results;
      _results = [];
      for (i = 0, _ref = this.players.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        if (this.players[i] === player) {
          this.scores[i] += inc;
          break;
        }
      }
      return _results;
    };
    ScoreTracker.prototype.getPlayerScore = function(player) {
      var i, _ref;
      for (i = 0, _ref = this.players.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        if (this.players[i] === player) {
          return this.scores[i];
        }
      }
    };
    ScoreTracker.prototype.recordGame = function(state) {
      var winner, winners, _i, _len;
      if (state.gameIsOver()) {
        winners = state.getWinners();
        for (_i = 0, _len = winners.length; _i < _len; _i++) {
          winner = winners[_i];
          this.incrementPlayerScore(winner, 1.0 / winners.length);
        }
        this.games += 1;
        return this.updateScores();
      }
    };
    ScoreTracker.prototype.errorMargin = function() {
      return 1.5 / Math.sqrt(this.games);
    };
    ScoreTracker.prototype.updateScores = function() {
      var score;
      this.proportions = (function() {
        var _i, _len, _ref, _results;
        _ref = this.scores;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          score = _ref[_i];
          _results.push(score / this.games);
        }
        return _results;
      }).call(this);
      if (this.scoreElt != null) {
        return this.updateScoresOnPage();
      }
    };
    ScoreTracker.prototype.decisiveWinner = function() {
      var i, _ref;
      for (i = 0, _ref = this.players.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        if (this.proportions[i] - this.errorMargin() > 1 / this.scores.length) {
          return this.players[i];
        }
      }
      return null;
    };
    ScoreTracker.prototype.updateScoresOnPage = function() {
      var i, pieces, _ref;
      pieces = [];
      for (i = 0, _ref = this.players.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        pieces.push("<div>\n  <span class=\"player" + (i + 1) + "\">" + this.players[i] + "</span>:\n  " + this.scores[i] + " wins (" + (roundPercentage(this.proportions[i])) + "%)\n</div>");
      }
      return this.scoreElt.html(pieces.join(''));
    };
    return ScoreTracker;
  })();
  roundPercentage = function(num) {
    return (num * 100).toFixed(1);
  };
  this.ScoreTracker = ScoreTracker;
}).call(this);
