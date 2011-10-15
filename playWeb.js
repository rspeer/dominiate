(function() {
  var BasicAI, PlayerState, State, action, applyBenefit, attack, basicCard, c, cloneDominionObject, compileStrategies, countInList, countStr, duration, makeCard, makeStrategy, noColony, numericSort, playFast, playGame, playStep, prize, shuffle, stringify, transferCard, transferCardToTop, treasure, upgradeChoices, _ref;
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty;
  compileStrategies = function(scripts, errorHandler) {
    var i, strategies, strategy, usedNames, _ref, _ref2;
    strategies = [];
    usedNames = [];
    for (i = 0, _ref = scripts.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
      try {
        strategy = CoffeeScript.eval(scripts[i], {
          bare: true
        });
        while (_ref2 = strategy.name, __indexOf.call(usedNames, _ref2) >= 0) {
          strategy.name += "Clone";
        }
        usedNames.push(strategy.name);
        strategies.push(strategy);
      } catch (e) {
        errorHandler(e);
        return null;
      }
    }
    return strategies;
  };
  makeStrategy = function(changes) {
    var ai, key, value;
    ai = new BasicAI();
    for (key in changes) {
      value = changes[key];
      ai[key] = value;
    }
    return ai;
  };
  playGame = function(strategies, options, ret) {
    var ai, ais, item, state, tableau;
    ais = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = strategies.length; _i < _len; _i++) {
        item = strategies[_i];
        _results.push(makeStrategy(item));
      }
      return _results;
    })();
    options.tracker.setPlayers((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = ais.length; _i < _len; _i++) {
        ai = ais[_i];
        _results.push(ai.name);
      }
      return _results;
    })());
    options.grapher.setPlayers((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = ais.length; _i < _len; _i++) {
        ai = ais[_i];
        _results.push(ai.name);
      }
      return _results;
    })());
    if (options.colonies) {
      tableau = tableaux.all;
    } else {
      tableau = tableaux.noColony;
    }
    if (options.randomizeOrder) {
      shuffle(ais);
    }
    state = new State().initialize(ais, tableau, options.log);
    if (ret == null) {
      ret = options.log;
    }
    if (options.fast) {
      options.log = function() {};
      return playFast(state, options, ret);
    } else {
      return window.setZeroTimeout(function() {
        return playStep(state, options, ret);
      });
    }
  };
  playStep = function(state, options, ret) {
    var errorHandler, _ref;
    if (state.gameIsOver()) {
      return ret(state);
    } else {
      try {
        state.doPlay();
        if (state.phase === 'buy' && (!state.extraturn) && (options.grapher != null)) {
          options.grapher.recordMoney(state.current.ai.name, state.current.turnsTaken, state.current.coins);
        }
        if (state.phase === 'cleanup' && (!state.extraturn) && (options.grapher != null)) {
          options.grapher.recordVP(state.current.ai.name, state.current.turnsTaken, state.current.getVP(state));
        }
        return window.setZeroTimeout(function() {
          return playStep(state, options, ret);
        });
      } catch (err) {
        errorHandler = (_ref = options.errorHandler) != null ? _ref : typeof alert !== "undefined" && alert !== null ? alert : console.log;
        errorHandler(err.message);
        return window.donePlaying();
      }
    }
  };
  playFast = function(state, options, ret) {
    var errorHandler, _ref;
    while (!state.gameIsOver()) {
      try {
        state.doPlay();
        if (state.phase === 'buy' && (!state.extraturn) && (options.grapher != null)) {
          options.grapher.recordMoney(state.current.ai.name, state.current.turnsTaken, state.current.coins);
        }
        if (state.phase === 'cleanup' && (!state.extraturn) && (options.grapher != null)) {
          options.grapher.recordVP(state.current.ai.name, state.current.turnsTaken, state.current.getVP(state));
        }
      } catch (err) {
        errorHandler = (_ref = options.errorHandler) != null ? _ref : typeof alert !== "undefined" && alert !== null ? alert : console.log;
        errorHandler(err.message);
        window.donePlaying();
      }
    }
    return ret(state);
  };
  this.compileStrategies = compileStrategies;
  this.playGame = playGame;
  BasicAI = (function() {
    function BasicAI() {
      this.copy = __bind(this.copy, this);
      this.trashOppTreasureValue = __bind(this.trashOppTreasureValue, this);
      this.herbalistValue = __bind(this.herbalistValue, this);
      this.putOnDeckValue = __bind(this.putOnDeckValue, this);
      this.discardValue = __bind(this.discardValue, this);
    }
    BasicAI.prototype.name = 'Basic AI';
    BasicAI.prototype.author = 'rspeer';
    BasicAI.cachedAP = [];
    BasicAI.prototype.myPlayer = function(state) {
      var player, _i, _len, _ref;
      _ref = state.players;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        player = _ref[_i];
        if (player.ai === this) {
          return player;
        }
      }
      throw new Error("" + this + " is being asked to make a decision, but isn't playing the game...?");
    };
    BasicAI.prototype.chooseByPriorityAndValue = function(state, choices, priorityfunc, valuefunc) {
      var bestChoice, bestValue, choice, choiceSet, my, preference, priority, value, _i, _j, _k, _len, _len2, _len3;
      my = this.myPlayer(state);
      if (choices.length === 0) {
        return null;
      }
      if (priorityfunc != null) {
        choiceSet = {};
        for (_i = 0, _len = choices.length; _i < _len; _i++) {
          choice = choices[_i];
          choiceSet[choice] = choice;
        }
        priority = priorityfunc(state, my);
        for (_j = 0, _len2 = priority.length; _j < _len2; _j++) {
          preference = priority[_j];
          if (preference === null && __indexOf.call(choices, null) >= 0) {
            return null;
          }
          if (choiceSet[preference] != null) {
            return choiceSet[preference];
          }
        }
      }
      if (valuefunc != null) {
        bestChoice = null;
        bestValue = -Infinity;
        for (_k = 0, _len3 = choices.length; _k < _len3; _k++) {
          choice = choices[_k];
          if ((choice === null) || (choice === false)) {
            value = 0;
          } else {
            value = valuefunc(state, choice, my);
          }
          if (value > bestValue) {
            bestValue = value;
            bestChoice = choice;
          }
        }
        if (__indexOf.call(choices, bestChoice) >= 0) {
          return bestChoice;
        }
      }
      if (__indexOf.call(choices, null) >= 0) {
        return null;
      }
      state.warn("" + this + " has no idea what to choose from " + choices);
      return choices[0];
    };
    BasicAI.prototype.choiceToValue = function(type, state, choice) {
      var index, my, priority, priorityfunc, valuefunc;
      if (choice === null) {
        return 0;
      }
      my = this.myPlayer(state);
      priorityfunc = this[type + 'Priority'];
      valuefunc = this[type + 'Value'];
      if (priorityfunc != null) {
        priority = priorityfunc(state, my);
      } else {
        priority = [];
      }
      index = priority.indexOf(stringify(choice));
      if (index !== -1) {
        return (priority.length - index) * 100;
      } else if (valuefunc != null) {
        return valuefunc(state, choice, my);
      } else {
        return 0;
      }
    };
    BasicAI.prototype.choose = function(type, state, choices) {
      var priorityfunc, valuefunc;
      priorityfunc = this[type + 'Priority'];
      valuefunc = this[type + 'Value'];
      return this.chooseByPriorityAndValue(state, choices, priorityfunc, valuefunc);
    };
    BasicAI.prototype.chooseAction = function(state, choices) {
      return this.choose('action', state, choices);
    };
    BasicAI.prototype.chooseTreasure = function(state, choices) {
      return this.choose('treasure', state, choices);
    };
    BasicAI.prototype.chooseGain = function(state, choices) {
      return this.choose('gain', state, choices);
    };
    BasicAI.prototype.chooseDiscard = function(state, choices) {
      return this.choose('discard', state, choices);
    };
    BasicAI.prototype.chooseTrash = function(state, choices) {
      return this.choose('trash', state, choices);
    };
    BasicAI.prototype.gainPriority = function(state, my) {
      var _ref, _ref2;
      return [my.countInDeck("Platinum") > 0 ? "Colony" : void 0, state.countInSupply("Colony") <= 6 ? "Province" : void 0, (0 < (_ref = state.gainsToEndGame()) && _ref <= 5) ? "Duchy" : void 0, (0 < (_ref2 = state.gainsToEndGame()) && _ref2 <= 2) ? "Estate" : void 0, "Platinum", "Gold", "Silver", state.gainsToEndGame() <= 3 ? "Copper" : void 0];
    };
    BasicAI.prototype.actionPriority = function(state, my) {
      var countInHandCopper, wantsToTrash, _ref;
      wantsToTrash = my.ai.wantsToTrash(state);
      countInHandCopper = my.countInHand("Copper");
      return [my.menagerieDraws() === 3 ? "Menagerie" : void 0, my.shantyTownDraws(true) === 2 ? "Shanty Town" : void 0, my.countInHand("Province") > 0 ? "Tournament" : void 0, state.gainsToEndGame() >= 5 || (_ref = state.cardInfo.Curse, __indexOf.call(my.draw, _ref) >= 0) ? "Lookout" : void 0, "Bag of Gold", "Apothecary", "Scout", "Trusty Steed", "Festival", "University", "Farming Village", "Bazaar", "Worker's Village", "City", "Walled Village", "Fishing Village", "Village", "Grand Market", "Hunting Party", "Alchemist", "Laboratory", "Caravan", "Market", "Peddler", "Treasury", my.inPlay.length >= 2 ? "Conspirator" : void 0, "Familiar", "Great Hall", "Wishing Well", "Lighthouse", "Haven", my.actions > 1 && my.hand.length <= 4 ? "Library" : void 0, my.actions > 1 ? "Rabble" : void 0, my.actions > 1 ? "Smithy" : void 0, my.actions > 1 && my.hand.length <= 4 ? "Watchtower" : void 0, my.actions > 1 && my.hand.length <= 5 ? "Library" : void 0, my.actions > 1 && (my.discard.length + my.draw.length) <= 3 ? "Courtyard" : void 0, wantsToTrash ? "Upgrade" : void 0, "Pawn", "Warehouse", "Cellar", my.actions > 1 && my.hand.length <= 6 ? "Library" : void 0, "Tournament", "Menagerie", my.actions < 2 ? "Shanty Town" : void 0, "Nobles", my.countInHand("Treasure Map") >= 2 ? "Treasure Map" : void 0, "Followers", "Mountebank", "Witch", "Torturer", "Sea Hag", "Tribute", "Goons", "Wharf", "Tactician", "Masquerade", "Vault", "Princess", my.countInHand("Province") >= 1 ? "Explorer" : void 0, my.hand.length <= 3 ? "Library" : void 0, "Expand", "Remodel", "Jester", "Militia", "Cutpurse", "Bridge", "Horse Traders", "Steward", countInHandCopper >= 1 ? "Moneylender" : void 0, "Mine", countInHandCopper >= 3 ? "Coppersmith" : void 0, my.hand.length <= 4 ? "Library" : void 0, "Rabble", "Smithy", my.hand.length <= 3 ? "Watchtower" : void 0, "Council Room", my.hand.length <= 5 ? "Library" : void 0, my.hand.length <= 4 ? "Watchtower" : void 0, (my.discard.length + my.draw.length) > 0 ? "Courtyard" : void 0, "Merchant Ship", my.countInHand("Estate") >= 1 ? "Baron" : void 0, "Monument", "Remake", "Adventurer", "Harvest", "Explorer", "Woodcutter", "Chancellor", "Counting House", countInHandCopper >= 2 ? "Coppersmith" : void 0, state.extraturn === false ? "Outpost" : void 0, wantsToTrash ? "Ambassador" : void 0, wantsToTrash + my.countInHand("Silver") >= 2 ? "Trading Post" : void 0, wantsToTrash ? "Chapel" : void 0, wantsToTrash ? "Trade Route" : void 0, my.ai.choose('mint', state, my.hand) ? "Mint" : void 0, "Pirate Ship", "Thief", "Fortune Teller", "Bureaucrat", my.actions < 2 ? "Conspirator" : void 0, "Herbalist", "Moat", my.hand.length <= 6 ? "Library" : void 0, my.hand.length <= 5 ? "Watchtower" : void 0, "Ironworks", "Workshop", state.smugglerChoices().length > 1 ? "Smugglers" : void 0, "Coppersmith", "Saboteur", my.hand.length <= 7 ? "Library" : void 0, my.countInDeck("Gold") >= 4 && state.current.countInDeck("Treasure Map") === 1 ? "Treasure Map" : void 0, "Shanty Town", "Chapel", "Library", "Conspirator", null, "Watchtower", "Trade Route", "Treasure Map", "Ambassador"];
    };
    BasicAI.prototype.treasurePriority = function(state, my) {
      return ["Platinum", "Diadem", "Philosopher's Stone", "Gold", "Hoard", "Royal Seal", "Harem", "Silver", "Quarry", "Talisman", "Copper", "Potion", "Loan", "Venture", "Bank", my.numUniqueCardsInPlay() >= 2 ? "Horn of Plenty" : void 0];
    };
    BasicAI.prototype.cachedActionPriority = function(state, my) {
      return my.ai.cachedAP;
    };
    BasicAI.prototype.cacheActionPriority = function(state, my) {
      return this.cachedAP = my.ai.actionPriority(state, my);
    };
    BasicAI.prototype.chooseOrderOnDeck = function(state, cards, my) {
      var choice, sorter;
      sorter = function(card1, card2) {
        return my.ai.choiceToValue('discard', state, card1) - my.ai.choiceToValue('discard', state, card2);
      };
      choice = cards.slice(0);
      return choice.sort(sorter);
    };
    BasicAI.prototype.mintValue = function(state, card, my) {
      return card.cost - 1;
    };
    BasicAI.prototype.discardPriority = function(state, my) {
      return ["Vineyard", "Colony", "Duke", "Duchy", "Gardens", "Province", "Curse", "Estate"];
    };
    BasicAI.prototype.discardValue = function(state, card, my) {
      if ((card.isAction && card.actions === 0 && my.actionBalance() <= 0) || (my.actions === 0)) {
        return 20 - card.cost;
      } else {
        return 0 - card.cost;
      }
    };
    BasicAI.prototype.putOnDeckPriority = function(state, my) {
      var card, margin, putBack, putBackOptions, treasures, _i, _j, _len, _len2, _ref;
      putBack = [];
      if (my.countPlayableTerminals(state) === 0) {
        putBackOptions = (function() {
          var _i, _len, _ref, _results;
          _ref = my.hand;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            card = _ref[_i];
            if (card.isAction) {
              _results.push(card);
            }
          }
          return _results;
        })();
      } else {
        putBackOptions = (function() {
          var _i, _len, _ref, _results;
          _ref = my.hand;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            card = _ref[_i];
            if (card.isAction && card.getActions(state) === 0) {
              _results.push(card);
            }
          }
          return _results;
        })();
      }
      putBack = (function() {
        var _i, _len, _ref, _ref2, _results;
        _ref = my.ai.actionPriority(state, my);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          card = _ref[_i];
          if ((_ref2 = state.cardInfo[card], __indexOf.call(putBackOptions, _ref2) >= 0)) {
            _results.push(card);
          }
        }
        return _results;
      })();
      putBack = putBack.slice(my.countPlayableTerminals(state), putBack.length);
      if (putBack.length === 0) {
        treasures = [];
        _ref = my.hand;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          card = _ref[_i];
          if (card.isTreasure && (!(__indexOf.call(treasures, card) >= 0))) {
            treasures.push(card);
          }
        }
        treasures.sort(function(x, y) {
          return x.coins - y.coins;
        });
        margin = my.ai.coinLossMargin(state);
        for (_j = 0, _len2 = treasures.length; _j < _len2; _j++) {
          card = treasures[_j];
          if (my.ai.coinsDueToCard(state, card) <= margin) {
            putBack.push(card);
          }
        }
        if (my.countInPlay(state.cardInfo["Alchemist"]) > 0) {
          if (__indexOf.call(putBack, "Potion") >= 0) {
            putBack.remove(state.cardInfo["Potion"]);
          }
        }
      }
      if (putBack.length === 0) {
        putBack = [my.ai.chooseDiscard(state, my.hand)];
      }
      return putBack;
    };
    BasicAI.prototype.putOnDeckValue = function(state, card, my) {
      return this.discardValue(state, card, my);
    };
    BasicAI.prototype.herbalistValue = function(state, card, my) {
      return this.mintValue(state, card, my);
    };
    BasicAI.prototype.trashPriority = function(state, my) {
      return ["Curse", state.gainsToEndGame() > 4 ? "Estate" : void 0, my.getTotalMoney() > 4 ? "Copper" : void 0, my.turnsTaken >= 10 ? "Potion" : void 0, state.gainsToEndGame() > 2 ? "Estate" : void 0];
    };
    BasicAI.prototype.trashValue = function(state, card, my) {
      return 0 - card.vp - card.cost;
    };
    BasicAI.prototype.benefitValue = function(state, choice, my) {
      var actionBalance, actionValue, buyValue, cardValue, coinValue, trashValue, usableActions, value, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
      buyValue = 1;
      cardValue = 2;
      coinValue = 3;
      trashValue = 4;
      actionValue = 10;
      actionBalance = my.actionBalance();
      usableActions = Math.max(0, -actionBalance);
      if (actionBalance >= 1) {
        cardValue += actionBalance;
      }
      if (my.ai.wantsToTrash(state) < ((_ref = choice.trash) != null ? _ref : 0)) {
        trashValue = -4;
      }
      value = cardValue * ((_ref2 = choice.cards) != null ? _ref2 : 0);
      value += coinValue * ((_ref3 = choice.coins) != null ? _ref3 : 0);
      value += buyValue * ((_ref4 = choice.buys) != null ? _ref4 : 0);
      value += trashValue * ((_ref5 = choice.trash) != null ? _ref5 : 0);
      value += actionValue * Math.min((_ref6 = choice.actions) != null ? _ref6 : 0, usableActions);
      return value;
    };
    BasicAI.prototype.ambassadorPriority = function(state, my) {
      return ["Curse,2", "Curse,1", "Curse,0", "Ambassador,2", "Estate,2", "Estate,1", my.getTreasureInHand() < 3 && my.getTotalMoney() >= 5 ? "Copper,2" : void 0, my.getTreasureInHand() >= 5 ? "Copper,2" : void 0, my.getTreasureInHand() === 3 && my.getTotalMoney() >= 7 ? "Copper,2" : void 0, my.getTreasureInHand() < 3 && my.getTotalMoney() >= 4 ? "Copper,1" : void 0, my.getTreasureInHand() >= 4 ? "Copper,1" : void 0, "Estate,0", "Copper,0"];
    };
    BasicAI.prototype.islandPriority = function(state, my) {};
    ["Colony", "Province", "Fairgrounds", "Duchy", "Duke", "Gardens", "Vineyard", "Estate", "Copper", "Curse", "Island"];
    BasicAI.prototype.cardInDeckValue = function(state, card, my) {
      var endgamePower;
      endgamePower = 1;
      if (state.gainsToEndGame() <= 5) {
        endgamePower = 3;
      }
      return -(this.choiceToValue('trash', state, card)) + Math.pow(this.choiceToValue('gain', state, card), endgamePower);
    };
    BasicAI.prototype.upgradeValue = function(state, choice, my) {
      var newCard, oldCard;
      oldCard = choice[0], newCard = choice[1];
      return my.ai.cardInDeckValue(state, newCard, my) - my.ai.cardInDeckValue(state, oldCard, my);
    };
    BasicAI.prototype.baronDiscardPriority = function(state, my) {
      return [true];
    };
    BasicAI.prototype.tournamentDiscardPriority = function(state, my) {
      return [true];
    };
    BasicAI.prototype.wishValue = function(state, card, my) {
      var pile;
      pile = my.draw;
      if (pile.length === 0) {
        pile = my.discard;
      }
      return countInList(pile, card);
    };
    BasicAI.prototype.gainOnDeckValue = function(state, card, my) {
      if (card.isAction || card.isTreasure) {
        return 1;
      } else {
        return -1;
      }
    };
    BasicAI.prototype.reshuffleValue = function(state, choice, my) {
      var card, junkToDraw, proportion, totalJunk, _i, _j, _len, _len2, _ref, _ref2;
      junkToDraw = 0;
      totalJunk = 0;
      _ref = my.draw;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        if (!(card.isAction || card.isTreasure)) {
          junkToDraw++;
        }
      }
      _ref2 = my.getDeck();
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        card = _ref2[_j];
        if (!(card.isAction || card.isTreasure)) {
          totalJunk++;
        }
      }
      if (totalJunk === 0) {
        return 1;
      }
      proportion = junkToDraw / totalJunk;
      return proportion - 0.5;
    };
    BasicAI.prototype.torturerPriority = function(state, my) {
      return [state.countInSupply("Curse") === 0 ? 'curse' : void 0, my.ai.wantsToDiscard(state) >= 2 ? 'discard' : void 0, my.hand.length <= 1 ? 'discard' : void 0, my.trashingInHand() > 0 ? 'curse' : void 0, my.hand.length <= 3 ? 'curse' : void 0, 'discard', 'curse'];
    };
    BasicAI.prototype.pirateShipPriority = function(state, my) {
      return [state.current.mats.pirateShip >= 5 && state.current.getAvailableMoney() + state.current.mats.pirateShip >= 8 ? 'coins' : void 0, 'attack'];
    };
    BasicAI.prototype.librarySetAsideValue = function(state, card, my) {
      return [my.actions === 0 && card.isAction ? 1 : -1];
    };
    BasicAI.prototype.trashOppTreasureValue = function(state, card, my) {
      if (card === 'Diadem') {
        return 5;
      }
      return card.cost;
    };
    BasicAI.prototype.wantsToTrash = function(state) {
      var card, my, trashableCards, _i, _len, _ref;
      my = this.myPlayer(state);
      trashableCards = 0;
      _ref = my.hand;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        if (this.chooseTrash(state, [card, null]) === card) {
          trashableCards += 1;
        }
      }
      return trashableCards;
    };
    BasicAI.prototype.wantsToDiscard = function(state) {
      var card, discardableCards, my, _i, _len, _ref;
      my = this.myPlayer(state);
      discardableCards = 0;
      _ref = my.hand;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        if (this.chooseDiscard(state, [card, null]) === card) {
          discardableCards += 1;
        }
      }
      return discardableCards;
    };
    BasicAI.prototype.pessimisticMoneyInHand = function(state) {
      var buyPhase;
      if (state.depth > 0) {
        return this.myPlayer(state).getAvailableMoney();
      }
      buyPhase = this.pessimisticBuyPhase(state);
      return buyPhase.current.coins;
    };
    BasicAI.prototype.pessimisticBuyPhase = function(state) {
      var hypothesis, hypothetically_my, oldDiscard, oldDraws, _ref;
      if (state.depth > 0) {
        if (state.phase === 'action') {
          state.phase = 'treasure';
        } else if (state.phase === 'treasure') {
          state.phase = 'buy';
        }
      }
      _ref = state.hypothetical(this), hypothesis = _ref[0], hypothetically_my = _ref[1];
      oldDraws = hypothetically_my.draw.slice(0);
      oldDiscard = hypothetically_my.discard.slice(0);
      hypothetically_my.draw = [];
      hypothetically_my.discard = [];
      while (hypothesis.phase !== 'buy') {
        hypothesis.doPlay();
      }
      hypothetically_my.draw = oldDraws;
      hypothetically_my.discard = oldDiscard;
      return hypothesis;
    };
    BasicAI.prototype.pessimisticCardsGained = function(state) {
      var newState;
      newState = this.pessimisticBuyPhase(state);
      newState.doPlay();
      return newState.current.gainedThisTurn;
    };
    BasicAI.prototype.coinLossMargin = function(state) {
      var cardToBuy, coins, coinsCost, newState, potionsCost, _ref;
      newState = this.pessimisticBuyPhase(state);
      coins = newState.coins;
      cardToBuy = newState.getSingleBuyDecision();
      if (cardToBuy === null) {
        return 0;
      }
      _ref = cardToBuy.getCost(newState), coinsCost = _ref[0], potionsCost = _ref[1];
      return coins - coinsCost;
    };
    BasicAI.prototype.coinsDueToCard = function(state, card) {
      var aCard, banks, c, nonbanks, value;
      c = state.cardInfo;
      value = card.getCoins(state);
      if (card.isTreasure) {
        banks = state.current.countInHand(c.Bank);
        value += banks;
        if (card === state.cardInfo.Bank) {
          nonbanks = ((function() {
            var _i, _len, _ref, _results;
            _ref = state.current.hand;
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              aCard = _ref[_i];
              if (aCard.isTreasure) {
                _results.push(aCard);
              }
            }
            return _results;
          })()).length;
          value += nonbanks;
        }
      }
      return value;
    };
    BasicAI.prototype.copy = function() {
      var ai, key, value;
      ai = new BasicAI();
      for (key in this) {
        value = this[key];
        ai[key] = value;
      }
      ai.name = this.name + '*';
      return ai;
    };
    BasicAI.prototype.toString = function() {
      return this.name;
    };
    return BasicAI;
  })();
  this.BasicAI = BasicAI;
  countInList = function(list, elt) {
    var count, member, _i, _len;
    count = 0;
    for (_i = 0, _len = list.length; _i < _len; _i++) {
      member = list[_i];
      if (member === elt) {
        count++;
      }
    }
    return count;
  };
  stringify = function(obj) {
    if (obj === null) {
      return null;
    } else {
      return obj.toString();
    }
  };
  c = {};
  this.c = c;
  c.allCards = [];
  makeCard = function(name, origCard, props, fake) {
    var key, newCard, value;
    newCard = {};
    for (key in origCard) {
      value = origCard[key];
      newCard[key] = value;
    }
    newCard.name = name;
    for (key in props) {
      value = props[key];
      newCard[key] = value;
    }
    newCard.parent = origCard.name;
    if (!fake) {
      c[name] = newCard;
      c.allCards.push(name);
    }
    return newCard;
  };
  basicCard = {
    isAction: false,
    isTreasure: false,
    isVictory: false,
    isAttack: false,
    isReaction: false,
    isDuration: false,
    isPrize: false,
    cost: 0,
    costPotion: 0,
    costInCoins: function(state) {
      return this.cost;
    },
    costInPotions: function(state) {
      return this.costPotion;
    },
    getCost: function(state) {
      var coins;
      coins = this.costInCoins(state);
      coins -= state.bridges;
      coins -= state.princesses * 2;
      if (this.isAction) {
        coins -= state.quarries * 2;
      }
      if (coins < 0) {
        coins = 0;
      }
      return [coins, this.costInPotions(state)];
    },
    actions: 0,
    cards: 0,
    coins: 0,
    buys: 0,
    vp: 0,
    trash: 0,
    getActions: function(state) {
      return this.actions;
    },
    getCards: function(state) {
      return this.cards;
    },
    getCoins: function(state) {
      return this.coins;
    },
    getBuys: function(state) {
      return this.buys;
    },
    getTrash: function(state) {
      return this.trash;
    },
    getVP: function(state) {
      return this.vp;
    },
    getPotion: function(state) {
      return 0;
    },
    mayBeBought: function(state) {
      return true;
    },
    startingSupply: function(state) {
      return 10;
    },
    buyEffect: function(state) {},
    gainEffect: function(state) {},
    playEffect: function(state) {},
    gainInPlayEffect: function(state, card) {},
    buyInPlayEffect: function(state, card) {},
    cleanupEffect: function(state) {},
    durationEffect: function(state) {},
    shuffleEffect: function(state) {},
    attackReaction: function(state, player) {},
    gainReaction: function(state, player, card, gainInHand) {},
    onPlay: function(state) {
      var cardsToDraw, cardsToTrash;
      state.current.actions += this.getActions(state);
      state.current.coins += this.getCoins(state);
      state.current.potions += this.getPotion(state);
      state.current.buys += this.getBuys(state);
      cardsToDraw = this.getCards(state);
      cardsToTrash = this.getTrash(state);
      if (cardsToDraw > 0) {
        state.drawCards(state.current, cardsToDraw);
      }
      if (cardsToTrash > 0) {
        state.requireTrash(state.current, cardsToTrash);
      }
      return this.playEffect(state);
    },
    onDuration: function(state) {
      return this.durationEffect(state);
    },
    onCleanup: function(state) {
      return this.cleanupEffect(state);
    },
    onBuy: function(state) {
      return this.buyEffect(state);
    },
    onGain: function(state) {
      return this.gainEffect(state);
    },
    reactToAttack: function(state, player) {
      return this.attackReaction(state, player);
    },
    reactToGain: function(state, player, card) {
      return this.gainReaction(state, player, card);
    },
    toString: function() {
      return this.name;
    }
  };
  makeCard('Curse', basicCard, {
    cost: 0,
    vp: -1,
    startingSupply: function(state) {
      switch (state.nPlayers) {
        case 1:
        case 2:
          return 10;
        case 3:
          return 20;
        case 4:
          return 30;
        case 5:
          return 40;
        default:
          return 50;
      }
    }
  });
  makeCard('Estate', basicCard, {
    cost: 2,
    isVictory: true,
    vp: 1,
    startingSupply: function(state) {
      switch (state.nPlayers) {
        case 1:
        case 2:
          return 8;
        default:
          return 12;
      }
    }
  });
  makeCard('Duchy', c.Estate, {
    cost: 5,
    vp: 3
  });
  makeCard('Province', c.Estate, {
    cost: 8,
    vp: 6,
    startingSupply: function(state) {
      switch (state.nPlayers) {
        case 1:
        case 2:
          return 8;
        case 3:
        case 4:
          return 12;
        case 5:
          return 15;
        default:
          return 18;
      }
    }
  });
  makeCard('Colony', c.Estate, {
    cost: 11,
    vp: 10
  });
  makeCard('Silver', basicCard, {
    cost: 3,
    isTreasure: true,
    coins: 2,
    startingSupply: function(state) {
      return 40;
    }
  });
  makeCard('Copper', c.Silver, {
    cost: 0,
    coins: 1,
    getCoins: function(state) {
      var _ref;
      return (_ref = state.copperValue) != null ? _ref : 1;
    },
    startingSupply: function(state) {
      return 60;
    }
  });
  makeCard('Gold', c.Silver, {
    cost: 6,
    coins: 3,
    startingSupply: function(state) {
      return 30;
    }
  });
  makeCard('Platinum', c.Silver, {
    cost: 9,
    coins: 5,
    startingSupply: function(state) {
      return 12;
    }
  });
  makeCard('Potion', c.Silver, {
    cost: 4,
    coins: 0,
    getPotion: function(state) {
      return 1;
    },
    startingSupply: function(state) {
      return 16;
    }
  });
  action = makeCard('action', basicCard, {
    isAction: true
  }, true);
  makeCard('Village', action, {
    cost: 3,
    actions: 2,
    cards: 1
  });
  makeCard("Worker's Village", action, {
    cost: 4,
    actions: 2,
    cards: 1,
    buys: 1
  });
  makeCard('Laboratory', action, {
    cost: 5,
    actions: 1,
    cards: 2
  });
  makeCard('Smithy', action, {
    cost: 4,
    cards: 3
  });
  makeCard('Festival', action, {
    cost: 5,
    actions: 2,
    coins: 2,
    buys: 1
  });
  makeCard('Woodcutter', action, {
    cost: 3,
    coins: 2,
    buys: 1
  });
  makeCard('Market', action, {
    cost: 5,
    actions: 1,
    cards: 1,
    coins: 1,
    buys: 1
  });
  makeCard('Bazaar', action, {
    cost: 5,
    actions: 2,
    cards: 1,
    coins: 1
  });
  makeCard('Duke', c.Estate, {
    cost: 5,
    getVP: function(state) {
      return state.current.countInDeck('Duchy');
    }
  });
  makeCard('Fairgrounds', c.Estate, {
    cost: 6,
    getVP: function(state) {
      var card, deck, unique, _i, _len;
      unique = [];
      deck = state.current.getDeck();
      for (_i = 0, _len = deck.length; _i < _len; _i++) {
        card = deck[_i];
        if (__indexOf.call(unique, card) < 0) {
          unique.push(card);
        }
      }
      return 2 * Math.floor(unique.length / 5);
    }
  });
  makeCard('Gardens', c.Estate, {
    cost: 4,
    getVP: function(state) {
      return Math.floor(state.current.getDeck().length / 10);
    }
  });
  makeCard('Great Hall', c.Estate, {
    isAction: true,
    cost: 3,
    cards: +1,
    actions: +1
  });
  makeCard('Harem', c.Estate, {
    isTreasure: true,
    cost: 6,
    coins: 2,
    vp: 2
  });
  makeCard('Island', c.Estate, {
    isAction: true,
    cost: 4,
    vp: 2,
    playEffect: function(state) {
      var card;
      if (state.current.hand.length === 0) {
        state.log("…setting aside the Island (no other cards in hand).");
      } else {
        card = state.current.ai.choose('island', state, state.current.hand);
        state.log("…setting aside the Island and a " + card + ".");
        state.current.hand.remove(card);
        state.current.mats.island.push(card);
      }
      if (__indexOf.call(state.current.inPlay, this) >= 0) {
        state.current.inPlay.remove(this);
      }
      return state.current.mats.island.push(this);
    }
  });
  makeCard('Nobles', c.Estate, {
    isAction: true,
    cost: 6,
    vp: 2,
    playEffect: function(state) {
      var benefit;
      benefit = state.current.ai.choose('benefit', state, [
        {
          actions: 2
        }, {
          cards: 3
        }
      ]);
      return applyBenefit(state, benefit);
    }
  });
  makeCard('Vineyard', c.Estate, {
    cost: 0,
    costPotion: 1,
    getVP: function(state) {
      return Math.floor(state.current.numActionCardsInDeck() / 3);
    }
  });
  treasure = makeCard('treasure', c.Silver, {
    startingSupply: function(state) {
      return 10;
    }
  }, true);
  makeCard('Bank', treasure, {
    cost: 7,
    getCoins: function(state) {
      var card, coins, _i, _len, _ref;
      coins = 0;
      _ref = state.current.inPlay;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        if (card.isTreasure) {
          coins += 1;
        }
      }
      return coins;
    },
    playEffect: function(state) {
      return state.log("...which is worth " + (this.getCoins(state)) + ".");
    }
  });
  makeCard("Hoard", treasure, {
    cost: 6,
    buyInPlayEffect: function(state, card) {
      if (card.isVictory) {
        state.gainCard(state.current, c.Gold, 'discard', true);
        return state.log("...gaining a Gold.");
      }
    }
  });
  makeCard("Horn of Plenty", treasure, {
    cost: 5,
    coins: 0,
    playEffect: function(state) {
      var card, cardName, choice, choices, coins, limit, potions, _ref;
      limit = state.current.numUniqueCardsInPlay();
      choices = [];
      for (cardName in state.supply) {
        card = c[cardName];
        _ref = card.getCost(state), coins = _ref[0], potions = _ref[1];
        if (state.supply[cardName] > 0 && potions === 0 && coins <= limit) {
          choices.push(card);
        }
      }
      choice = state.gainOneOf(state.current, choices);
      if (choice.isVictory) {
        state.current.inPlay.remove(this);
        return state.log("..." + state.current.ai + " trashes the Horn of Plenty.");
      }
    }
  });
  makeCard('Loan', treasure, {
    coins: 1,
    playEffect: function(state) {
      var drawn, trash;
      drawn = state.current.dig(state, function(state, card) {
        return card.isTreasure;
      });
      if (drawn[0] != null) {
        treasure = drawn[0];
        trash = state.current.ai.choose('trash', state, [treasure, null]);
        if (trash != null) {
          state.log("...trashing the " + treasure + ".");
          return drawn.remove(treasure);
        } else {
          state.log("...discarding the " + treasure + ".");
          return state.current.discard.push(treasure);
        }
      }
    }
  });
  makeCard("Philosopher's Stone", treasure, {
    cost: 3,
    costPotion: 1,
    getCoins: function(state) {
      return Math.floor((state.current.draw.length + state.current.discard.length) / 5);
    },
    playEffect: function(state) {
      return state.log("...which is worth " + (this.getCoins(state)) + ".");
    }
  });
  makeCard('Quarry', treasure, {
    cost: 4,
    coins: 1,
    playEffect: function(state) {
      return state.quarries += 1;
    }
  });
  makeCard('Royal Seal', treasure, {
    cost: 5,
    gainInPlayEffect: function(state, card) {
      var player, source;
      player = state.current;
      if (player.gainLocation === 'trash') {
        return;
      }
      source = player[player.gainLocation];
      if (player.ai.choose('gainOnDeck', state, [card, null])) {
        state.log("...putting the " + card + " on top of the deck.");
        player.gainLocation = 'draw';
        return transferCardToTop(card, source, player.draw);
      }
    }
  });
  makeCard('Talisman', treasure, {
    cost: 4,
    coins: 1,
    buyInPlayEffect: function(state, card) {
      if (card.getCost(state)[0] <= 4 && !card.isVictory) {
        state.gainCard(state.current, card, 'discard', true);
        return state.log("...gaining a " + card + ".");
      }
    }
  });
  makeCard('Venture', treasure, {
    cost: 5,
    coins: 1,
    playEffect: function(state) {
      var drawn;
      drawn = state.current.dig(state, function(state, card) {
        return card.isTreasure;
      });
      if (drawn[0] != null) {
        treasure = drawn[0];
        state.log("...playing " + treasure + ".");
        state.current.inPlay.push(treasure);
        return treasure.onPlay(state);
      }
    }
  });
  duration = makeCard('duration', action, {
    durationActions: 0,
    durationBuys: 0,
    durationCoins: 0,
    durationCards: 0,
    isDuration: true,
    durationEffect: function(state) {
      state.current.actions += this.durationActions;
      state.current.buys += this.durationBuys;
      state.current.coins += this.durationCoins;
      if (this.durationCards > 0) {
        return state.drawCards(state.current, this.durationCards);
      }
    }
  }, true);
  makeCard('Haven', duration, {
    cost: 2,
    cards: +1,
    actions: +1,
    playEffect: function(state) {
      var cardInHaven;
      cardInHaven = state.current.ai.choose('putOnDeck', state, state.current.hand);
      if (cardInHaven != null) {
        state.log("" + state.current.ai + " sets aside a " + cardInHaven + " with Haven.");
        return transferCard(cardInHaven, state.current.hand, state.current.setAsideByHaven);
      } else {
        if (state.current.hand.length === 0) {
          return state.log("" + state.current.ai + " has no cards to set aside.");
        } else {
          return state.warn("hand not empty but no card set aside");
        }
      }
    },
    durationEffect: function(state) {
      var cardFromHaven;
      cardFromHaven = state.current.setAsideByHaven.pop();
      if (cardFromHaven != null) {
        state.log("" + state.current.ai + " picks up a " + cardFromHaven + " from Haven.");
        return state.current.hand.unshift(cardFromHaven);
      }
    }
  });
  makeCard('Caravan', duration, {
    cost: 4,
    cards: +1,
    actions: +1,
    durationCards: +1
  });
  makeCard('Fishing Village', duration, {
    cost: 3,
    coins: +1,
    actions: +2,
    durationActions: +1,
    durationCoins: +1
  });
  makeCard('Wharf', duration, {
    cost: 5,
    cards: +2,
    buys: +1,
    durationCards: +2,
    durationBuys: +1
  });
  makeCard('Merchant Ship', duration, {
    cost: 5,
    coins: +2,
    durationCoins: +2
  });
  makeCard('Lighthouse', duration, {
    cost: 2,
    actions: +1,
    coins: +1,
    durationCoins: +1
  });
  makeCard('Outpost', duration, {
    cost: 5
  });
  makeCard('Tactician', duration, {
    cost: 5,
    durationActions: +1,
    durationBuys: +1,
    durationCards: +5,
    playEffect: function(state) {
      var cardsInHand;
      cardsInHand = state.current.hand.length;
      if (cardsInHand > 0) {
        state.log("...discarding the whole hand.");
        state.current.tacticians++;
        state.current.discard = state.current.discard.concat(state.current.hand);
        return state.current.hand = [];
      }
    },
    cleanupEffect: function(state) {
      if (state.current.tacticians > 0) {
        return state.current.tacticians--;
      } else {
        state.log("" + state.current.ai + " discards an inactive Tactician.");
        return transferCard(c.Tactician, state.current.duration, state.current.discard);
      }
    }
  });
  makeCard('Remodel', action, {
    cost: 4,
    upgradeFilter: function(state, oldCard, newCard) {
      var coins1, coins2, potions1, potions2, _ref, _ref2;
      _ref = oldCard.getCost(state), coins1 = _ref[0], potions1 = _ref[1];
      _ref2 = newCard.getCost(state), coins2 = _ref2[0], potions2 = _ref2[1];
      return (potions1 >= potions2) && (coins1 + 2 >= coins2);
    },
    playEffect: function(state) {
      var choice, choices, newCard, oldCard;
      choices = upgradeChoices(state, state.current.hand, this.upgradeFilter);
      choice = state.current.ai.choose('upgrade', state, choices);
      if (choice !== null) {
        oldCard = choice[0], newCard = choice[1];
        state.current.doTrash(oldCard);
        return state.gainCard(state.current, newCard);
      }
    }
  });
  makeCard('Expand', c.Remodel, {
    cost: 7,
    upgradeFilter: function(state, oldCard, newCard) {
      var coins1, coins2, potions1, potions2, _ref, _ref2;
      _ref = oldCard.getCost(state), coins1 = _ref[0], potions1 = _ref[1];
      _ref2 = newCard.getCost(state), coins2 = _ref2[0], potions2 = _ref2[1];
      return (potions1 >= potions2) && (coins1 + 3 >= coins2);
    }
  });
  makeCard('Upgrade', c.Remodel, {
    cost: 5,
    actions: +1,
    cards: +1,
    upgradeFilter: function(state, oldCard, newCard) {
      var coins1, coins2, potions1, potions2, _ref, _ref2;
      _ref = oldCard.getCost(state), coins1 = _ref[0], potions1 = _ref[1];
      _ref2 = newCard.getCost(state), coins2 = _ref2[0], potions2 = _ref2[1];
      return (potions1 === potions2) && (coins1 + 1 === coins2);
    }
  });
  makeCard('Remake', c.Remodel, {
    upgradeFilter: function(state, oldCard, newCard) {
      var coins1, coins2, potions1, potions2, _ref, _ref2;
      _ref = oldCard.getCost(state), coins1 = _ref[0], potions1 = _ref[1];
      _ref2 = newCard.getCost(state), coins2 = _ref2[0], potions2 = _ref2[1];
      return (potions1 === potions2) && (coins1 + 1 === coins2);
    },
    playEffect: function(state) {
      var choice, choices, i, newCard, oldCard, _results;
      _results = [];
      for (i = 1; i <= 2; i++) {
        choices = upgradeChoices(state, state.current.hand, this.upgradeFilter);
        choice = state.current.ai.choose('upgrade', state, choices);
        _results.push(choice !== null ? ((oldCard = choice[0], newCard = choice[1], choice), state.current.doTrash(oldCard), state.gainCard(state.current, newCard)) : void 0);
      }
      return _results;
    }
  });
  makeCard('Mine', c.Remodel, {
    cost: 5,
    upgradeFilter: function(state, oldCard, newCard) {
      var coins1, coins2, potions1, potions2, _ref, _ref2;
      _ref = oldCard.getCost(state), coins1 = _ref[0], potions1 = _ref[1];
      _ref2 = newCard.getCost(state), coins2 = _ref2[0], potions2 = _ref2[1];
      return (potions1 >= potions2) && (coins1 + 3 >= coins2) && oldCard.isTreasure && newCard.isTreasure;
    },
    playEffect: function(state) {
      var choice, choices, newCard, oldCard;
      choices = upgradeChoices(state, state.current.hand, this.upgradeFilter);
      choice = state.current.ai.choose('upgrade', state, choices);
      if (choice !== null) {
        oldCard = choice[0], newCard = choice[1];
        state.current.doTrash(oldCard);
        return state.gainCard(state.current, newCard, 'hand');
      }
    }
  });
  prize = makeCard('prize', basicCard, {
    cost: 0,
    isPrize: true,
    isAction: true,
    mayBeBought: function(state) {
      return false;
    },
    startingSupply: function(state) {
      return 0;
    }
  }, true);
  makeCard('Bag of Gold', prize, {
    actions: +1,
    playEffect: function(state) {
      state.gainCard(state.current, c.Gold, 'draw');
      return state.log("...putting the Gold on top of the deck.");
    }
  });
  makeCard('Diadem', prize, {
    isAction: false,
    isTreasure: true,
    getCoins: function(state) {
      return 2 + state.current.actions;
    }
  });
  makeCard('Followers', prize, {
    cards: +2,
    isAttack: true,
    playEffect: function(state) {
      state.gainCard(state.current, c.Estate);
      return state.attackOpponents(function(opp) {
        state.gainCard(opp, c.Curse);
        if (opp.hand.length > 3) {
          return state.requireDiscard(opp, opp.hand.length - 3);
        }
      });
    }
  });
  makeCard('Princess', prize, {
    buys: 1,
    playEffect: function(state) {
      return state.princesses = 1;
    }
  });
  makeCard('Trusty Steed', prize, {
    playEffect: function(state) {
      var benefit;
      benefit = state.current.ai.choose('benefit', state, [
        {
          cards: 2,
          actions: 2
        }, {
          cards: 2,
          coins: 2
        }, {
          actions: 2,
          coins: 2
        }, {
          cards: 2,
          horseEffect: true
        }, {
          actions: 2,
          horseEffect: true
        }, {
          coins: 2,
          horseEffect: true
        }
      ]);
      return applyBenefit(state, benefit);
    }
  });
  attack = makeCard('attack', action, {
    isAttack: true
  }, true);
  makeCard('Ambassador', attack, {
    cost: 3,
    playEffect: function(state) {
      var card, cardName, choice, choices, count, counts, i, quantity, _i, _len, _ref, _ref2;
      counts = {};
      _ref = state.current.hand;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        if ((_ref2 = counts[card]) == null) {
          counts[card] = 0;
        }
        counts[card] += 1;
      }
      choices = [];
      for (card in counts) {
        count = counts[card];
        if (count >= 2) {
          choices.push([card, 2]);
        }
        if (count >= 1) {
          choices.push([card, 1]);
        }
        choices.push([card, 0]);
      }
      choice = state.current.ai.choose('ambassador', state, choices);
      if (choice !== null) {
        cardName = choice[0], quantity = choice[1];
        card = c[cardName];
        state.log("...choosing to return " + quantity + " " + cardName + ".");
        for (i = 0; 0 <= quantity ? i < quantity : i > quantity; 0 <= quantity ? i++ : i--) {
          state.current.doTrash(card);
        }
        if (state.supply[card] != null) {
          state.supply[card] += quantity;
        }
        return state.attackOpponents(function(opp) {
          return state.gainCard(opp, card);
        });
      }
    }
  });
  makeCard('Bureaucrat', attack, {
    cost: 4,
    playEffect: function(state) {
      state.gainCard(state.current, c.Silver, 'draw');
      return state.attackOpponents(function(opp) {
        var card, choice, victory, _i, _len, _ref;
        victory = [];
        _ref = opp.hand;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          card = _ref[_i];
          if (card.isVictory) {
            victory.push(card);
          }
        }
        if (victory.length === 0) {
          state.revealHand(opp);
          return state.log("" + opp.ai + " reveals a hand with no Victory cards.");
        } else {
          choice = opp.ai.choose('putOnDeck', state, victory);
          transferCardToTop(choice, opp.hand, opp.draw);
          return state.log("" + opp.ai + " returns " + choice + " to the top of the deck.");
        }
      });
    }
  });
  makeCard('Cutpurse', attack, {
    cost: 4,
    coins: +2,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        var _ref;
        if (_ref = c.Copper, __indexOf.call(opp.hand, _ref) >= 0) {
          return opp.doDiscard(c.Copper);
        } else {
          state.log("" + opp.ai + " has no Copper in hand.");
          return state.revealHand(opp);
        }
      });
    }
  });
  makeCard('Familiar', attack, {
    cost: 3,
    costPotion: 1,
    cards: +1,
    actions: +1,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        return state.gainCard(opp, c.Curse);
      });
    }
  });
  makeCard('Fortune Teller', attack, {
    cost: 3,
    coins: +2,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        var card, drawn;
        drawn = opp.dig(state, function(state, card) {
          return card.isVictory || card === c.Curse;
        });
        if (drawn[0] != null) {
          card = drawn[0];
          transferCardToTop(card, drawn, opp.draw);
          return state.log("..." + opp.ai + " puts " + card + " on top of the deck.");
        }
      });
    }
  });
  makeCard('Jester', attack, {
    cost: 5,
    coins: +2,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        var card;
        card = state.discardFromDeck(opp, 1)[0];
        if (card.isVictory) {
          return state.gainCard(opp, c.Curse);
        } else if (state.current.ai.chooseGain(state, [card, null])) {
          return state.gainCard(state.current, card);
        } else {
          return state.gainCard(opp, card);
        }
      });
    }
  });
  makeCard("Militia", attack, {
    cost: 4,
    coins: +2,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        if (opp.hand.length > 3) {
          return state.requireDiscard(opp, opp.hand.length - 3);
        }
      });
    }
  });
  makeCard("Goons", c.Militia, {
    cost: 6,
    buys: +1
  });
  makeCard("Mountebank", attack, {
    cost: 5,
    coins: +2,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        var _ref;
        if (_ref = c.Curse, __indexOf.call(opp.hand, _ref) >= 0) {
          return opp.doDiscard(c.Curse);
        } else {
          state.gainCard(opp, c.Copper);
          return state.gainCard(opp, c.Curse);
        }
      });
    }
  });
  makeCard('Pirate Ship', attack, {
    cost: 4,
    playEffect: function(state) {
      var attackSuccess, choice;
      choice = state.current.ai.choose('pirateShip', state, ['coins', 'attack']);
      if (choice === 'coins') {
        state.current.coins += state.current.mats.pirateShip;
        return state.log("...getting +$" + state.current.mats.pirateShip + ".");
      } else if (choice === 'attack') {
        state.log("...attacking the other players.");
        attackSuccess = false;
        state.attackOpponents(function(opp) {
          var card, drawn, drawnTreasures, treasureToTrash, _i, _len;
          drawn = opp.getCardsFromDeck(2);
          state.log("..." + opp.ai + " reveals " + drawn + ".");
          drawnTreasures = [];
          for (_i = 0, _len = drawn.length; _i < _len; _i++) {
            card = drawn[_i];
            if (card.isTreasure) {
              drawnTreasures.push(card);
            }
          }
          treasureToTrash = state.current.ai.choose('trashOppTreasure', state, drawnTreasures);
          if (treasureToTrash) {
            attackSuccess = true;
            drawn.remove(treasureToTrash);
            state.log("..." + state.current.ai + " trashes " + opp.ai + "'s " + treasureToTrash + ".");
          }
          state.current.discard.concat(drawn);
          return state.log("..." + opp.ai + " discards " + drawn + ".");
        });
        if (attackSuccess) {
          state.current.mats.pirateShip += 1;
          return state.log("..." + state.current.ai + " takes a Coin token (" + state.current.mats.pirateShip + " on the mat).");
        }
      }
    }
  });
  makeCard('Rabble', attack, {
    cost: 5,
    cards: +3,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        var card, drawn, order, _i, _len;
        drawn = opp.getCardsFromDeck(3);
        state.log("" + opp.ai + " draws " + drawn + ".");
        for (_i = 0, _len = drawn.length; _i < _len; _i++) {
          card = drawn[_i];
          if (card.isTreasure || card.isAction) {
            state.current.discard.push(card);
            state.log("...discarding " + card + ".");
          } else {
            state.current.setAside.push(card);
          }
        }
        if (state.current.setAside.length > 0) {
          order = state.current.ai.chooseOrderOnDeck(state, state.current.setAside, state.current);
          state.log("...putting " + order + " back on the deck.");
          state.current.draw = order.concat(state.current.draw);
          return state.current.setAside = [];
        }
      });
    }
  });
  makeCard('Saboteur', attack, {
    cost: 5,
    upgradeFilter: function(state, oldCard, newCard) {
      var coins1, coins2, potions1, potions2, _ref, _ref2;
      _ref = oldCard.getCost(state), coins1 = _ref[0], potions1 = _ref[1];
      _ref2 = newCard.getCost(state), coins2 = _ref2[0], potions2 = _ref2[1];
      return (potions1 >= potions2) && (coins1 - 2 >= coins2);
    },
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        var cardToTrash, choice, choices, drawn, newCard;
        drawn = opp.dig(state, function(state, card) {
          return card.getCost(state)[0] >= 3;
        });
        if (drawn[0] != null) {
          cardToTrash = drawn[0];
          state.log("..." + state.current.ai + " trashes " + opp.ai + "'s " + cardToTrash + ".");
          choices = upgradeChoices(state, drawn, c.Saboteur.upgradeFilter);
          choices.push([cardToTrash, null]);
          choice = opp.ai.choose('upgrade', state, choices);
          newCard = choice[1];
          if (newCard != null) {
            state.gainCard(opp, newCard, 'discard', true);
            return state.log("..." + opp.ai + " gains " + newCard + ".");
          } else {
            return state.log("..." + opp.ai + " gains nothing.");
          }
        }
      });
    }
  });
  makeCard('Sea Hag', attack, {
    cost: 4,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        state.discardFromDeck(opp, 1);
        state.gainCard(opp, c.Curse, 'draw', true);
        return state.log("" + opp.ai + " gains a Curse on top of the deck.");
      });
    }
  });
  makeCard('Thief', attack, {
    cost: 4,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        var card, cardToGain, drawn, drawnTreasures, treasureToTrash, _i, _len;
        drawn = opp.getCardsFromDeck(2);
        state.log("..." + opp.ai + " reveals " + drawn + ".");
        drawnTreasures = [];
        for (_i = 0, _len = drawn.length; _i < _len; _i++) {
          card = drawn[_i];
          if (card.isTreasure) {
            drawnTreasures.push(card);
          }
        }
        treasureToTrash = state.current.ai.choose('trashOppTreasure', state, drawnTreasures);
        if (treasureToTrash) {
          drawn.remove(treasureToTrash);
          state.log("..." + state.current.ai + " trashes " + opp.ai + "'s " + treasureToTrash + ".");
          cardToGain = state.current.ai.chooseGain(state, [treasureToTrash, null]);
          if (cardToGain) {
            state.gainCard(state.current, cardToGain, 'discard', true);
            state.log("..." + state.current.ai + " gains the trashed " + treasureToTrash + ".");
          }
        }
        state.current.discard.concat(drawn);
        return state.log("..." + opp.ai + " discards " + drawn + ".");
      });
    }
  });
  makeCard('Torturer', attack, {
    cost: 5,
    cards: +3,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        if (opp.ai.choose('torturer', state, ['curse', 'discard']) === 'curse') {
          return state.gainCard(opp, c.Curse, 'hand');
        } else {
          return state.requireDiscard(opp, 2);
        }
      });
    }
  });
  makeCard('Witch', attack, {
    cost: 5,
    cards: +2,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        return state.gainCard(opp, c.Curse);
      });
    }
  });
  makeCard('Adventurer', action, {
    cost: 6,
    playEffect: function(state) {
      var card, drawn, treasuresDrawn;
      treasuresDrawn = 0;
      while (treasuresDrawn < 2) {
        drawn = state.current.getCardsFromDeck(1);
        if (drawn.length === 0) {
          break;
        }
        card = drawn[0];
        if (card.isTreasure) {
          treasuresDrawn += 1;
          state.current.hand.push(card);
          state.log("...drawing a " + card + ".");
        } else {
          state.current.setAside.push(card);
        }
      }
      state.current.discard = state.current.discard.concat(state.current.setAside);
      return state.current.setAside = [];
    }
  });
  makeCard('Alchemist', action, {
    cost: 3,
    costPotion: 1,
    actions: +1,
    cards: +2,
    cleanupEffect: function(state) {
      var _ref;
      if (_ref = c.Potion, __indexOf.call(state.current.inPlay, _ref) >= 0) {
        return transferCardToTop(c.Alchemist, state.current.discard, state.current.draw);
      }
    }
  });
  makeCard('Apothecary', action, {
    cost: 2,
    costPotion: 1,
    cards: +1,
    actions: +1,
    playEffect: function(state) {
      var card, drawn, order, _i, _len;
      drawn = state.getCardsFromDeck(state.current, 4);
      state.log("...drawing " + drawn + ".");
      for (_i = 0, _len = drawn.length; _i < _len; _i++) {
        card = drawn[_i];
        if (card === c.Copper || card === c.Potion) {
          state.current.hand.push(card);
          state.log("...putting " + card + " in the hand.");
        } else {
          state.current.setAside.push(card);
        }
      }
      if (state.current.setAside.length > 0) {
        order = state.current.ai.chooseOrderOnDeck(state, state.current.setAside, state.current);
        state.log("...putting " + order + " back on the deck.");
        state.current.draw = order.concat(state.current.draw);
        return state.current.setAside = [];
      }
    }
  });
  makeCard('Baron', action, {
    cost: 4,
    buys: 1,
    playEffect: function(state) {
      var discardEstate, _ref;
      discardEstate = false;
      if (_ref = c.Estate, __indexOf.call(state.current.hand, _ref) >= 0) {
        discardEstate = state.current.ai.choose('baronDiscard', state, [true, false]);
      }
      if (discardEstate) {
        state.current.doDiscard(c.Estate);
        return state.current.coins += 4;
      } else {
        return state.gainCard(state.current.c.Estate);
      }
    }
  });
  makeCard('Bridge', action, {
    cost: 4,
    coins: 1,
    buys: 1,
    playEffect: function(state) {
      return state.bridges += 1;
    }
  });
  makeCard('Cellar', action, {
    cost: 2,
    actions: 1,
    playEffect: function(state) {
      var numDiscarded, startingCards;
      startingCards = state.current.hand.length;
      state.allowDiscard(state.current, Infinity);
      numDiscarded = startingCards - state.current.hand.length;
      return state.drawCards(state.current, numDiscarded);
    }
  });
  makeCard('Chancellor', action, {
    cost: 3,
    coins: +2,
    playEffect: function(state) {
      var draw, player;
      player = state.current;
      if (player.ai.choose('reshuffle', state, [true, false])) {
        state.log("...putting the draw pile into the discard pile.");
        draw = player.draw.slice(0);
        player.draw = [];
        return player.discard = player.discard.concat(draw);
      }
    }
  });
  makeCard('Chapel', action, {
    cost: 2,
    playEffect: function(state) {
      return state.allowTrash(state.current, 4);
    }
  });
  makeCard('City', action, {
    cost: 5,
    actions: +2,
    cards: +1,
    getCards: function(state) {
      if (state.numEmptyPiles() >= 1) {
        return 2;
      } else {
        return 1;
      }
    },
    getBuys: function(state) {
      if (state.numEmptyPiles() >= 2) {
        return 1;
      } else {
        return 0;
      }
    },
    getCoins: function(state) {
      if (state.numEmptyPiles() >= 2) {
        return 1;
      } else {
        return 0;
      }
    }
  });
  makeCard('Conspirator', action, {
    cost: 4,
    coins: 2,
    getActions: function(state) {
      if (state.current.inPlay.length >= 3) {
        return 1;
      } else {
        return 0;
      }
    },
    getCards: function(state) {
      if (state.current.inPlay.length >= 3) {
        return 1;
      } else {
        return 0;
      }
    }
  });
  makeCard('Coppersmith', action, {
    cost: 4,
    playEffect: function(state) {
      return state.copperValue += 1;
    }
  });
  makeCard('Council Room', action, {
    cost: 5,
    cards: 4,
    buys: 1,
    playEffect: function(state) {
      var opp, _i, _len, _ref, _results;
      _ref = state.players.slice(1);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        opp = _ref[_i];
        _results.push(state.drawCards(opp, 1));
      }
      return _results;
    }
  });
  makeCard('Counting House', action, {
    cost: 5,
    playEffect: function(state) {
      var card, coppersFromDiscard;
      coppersFromDiscard = (function() {
        var _i, _len, _ref, _results;
        _ref = state.current.discard;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          card = _ref[_i];
          if (card === c.Copper) {
            _results.push(card);
          }
        }
        return _results;
      })();
      state.current.discard = (function() {
        var _i, _len, _ref, _results;
        _ref = state.current.discard;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          card = _ref[_i];
          if (card !== c.Copper) {
            _results.push(card);
          }
        }
        return _results;
      })();
      Array.prototype.push.apply(state.current.hand, coppersFromDiscard);
      return state.log(("" + state.current.ai + " puts ") + coppersFromDiscard.length + " Coppers into his hand.");
    }
  });
  makeCard('Courtyard', action, {
    cost: 2,
    cards: 3,
    playEffect: function(state) {
      var card;
      card = state.current.ai.choose('putOnDeck', state, state.current.hand);
      return state.current.doPutOnDeck(card);
    }
  });
  makeCard('Cutpurse', action, {
    cost: 4,
    coins: +2,
    isAttack: true,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        var _ref;
        if (_ref = c.Copper, __indexOf.call(opp.hand, _ref) >= 0) {
          return opp.doDiscard(c.Copper);
        } else {
          state.log("" + opp.ai + " has no Copper in hand.");
          return state.revealHand(opp);
        }
      });
    }
  });
  makeCard('Explorer', action, {
    cost: 5,
    playEffect: function(state) {
      var cardToGain, _ref;
      cardToGain = c.Silver;
      if (_ref = c.Province, __indexOf.call(state.current.hand, _ref) >= 0) {
        state.log("…revealing a Province.");
        cardToGain = c.Gold;
      }
      if (state.countInSupply(cardToGain) > 0) {
        state.gainCard(state.current, cardToGain, 'hand', true);
        return state.log("…and gaining a " + cardToGain + ", putting it in the hand.");
      } else {
        return state.log("…but there are no " + cardToGain + "s available to gain.");
      }
    }
  });
  makeCard('Farming Village', action, {
    cost: 4,
    actions: 2,
    playEffect: function(state) {
      var card, cardsDrawn, drawn;
      cardsDrawn = 0;
      while (cardsDrawn < 1) {
        drawn = state.current.getCardsFromDeck(1);
        if (drawn.length === 0) {
          break;
        }
        card = drawn[0];
        if (card.isAction || card.isTreasure) {
          cardsDrawn += 1;
          state.current.hand.push(card);
          state.log("...drawing a " + card + ".");
        } else {
          state.current.setAside.push(card);
        }
      }
      state.current.discard = state.current.discard.concat(state.current.setAside);
      return state.current.setAside = [];
    }
  });
  makeCard("Grand Market", c.Market, {
    cost: 6,
    coins: 2,
    actions: 1,
    cards: 1,
    buys: 1,
    mayBeBought: function(state) {
      var _ref;
      return !(_ref = c.Copper, __indexOf.call(state.current.inPlay, _ref) >= 0);
    }
  });
  makeCard("Harvest", action, {
    cost: 5,
    playEffect: function(state) {
      var card, cards, unique, _i, _len;
      unique = [];
      cards = state.discardFromDeck(state.current, 4);
      for (_i = 0, _len = cards.length; _i < _len; _i++) {
        card = cards[_i];
        if (__indexOf.call(unique, card) < 0) {
          unique.push(card);
        }
      }
      state.current.coins += unique.length;
      return state.log("...gaining +$" + unique.length + ".");
    }
  });
  makeCard("Herbalist", action, {
    cost: 2,
    buys: +1,
    coins: +1,
    cleanupEffect: function(state) {
      var card, choice, choices, _i, _len, _ref;
      choices = [];
      _ref = state.current.inPlay;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        if (card.isTreasure) {
          choices.push(card);
        }
      }
      choices.push(null);
      choice = state.current.ai.choose('herbalist', state, choices);
      if (choice !== null) {
        state.log("" + state.current.ai + " uses Herbalist to put " + choice + " back on the deck.");
        return transferCardToTop(choice, state.current.inPlay, state.current.draw);
      }
    }
  });
  makeCard("Horse Traders", action, {
    cost: 4,
    buys: +1,
    coins: +3,
    isReaction: true,
    playEffect: function(state) {
      return state.requireDiscard(state.current, 2);
    },
    durationEffect: function(state) {
      transferCard(c['Horse Traders'], state.current.duration, state.current.hand);
      return state.drawCards(state.current, 1);
    },
    attackReaction: function(state, player) {
      return transferCard(c['Horse Traders'], player.hand, player.duration);
    }
  });
  makeCard('Hunting Party', action, {
    cost: 5,
    actions: +1,
    cards: +1,
    playEffect: function(state) {
      var card, cardsDrawn, drawn;
      state.revealHand(state.current);
      cardsDrawn = 0;
      while (cardsDrawn < 1) {
        drawn = state.current.getCardsFromDeck(1);
        if (drawn.length === 0) {
          break;
        }
        card = drawn[0];
        state.log("...revealing a " + card);
        if (__indexOf.call(state.current.hand, card) < 0) {
          cardsDrawn += 1;
          state.current.hand.push(card);
          state.log("...drawing a " + card + ".");
        } else {
          state.current.setAside.push(card);
        }
      }
      state.current.discard = state.current.discard.concat(state.current.setAside);
      return state.current.setAside = [];
    }
  });
  makeCard('Ironworks', action, {
    cost: 4,
    playEffect: function(state) {
      var card, cardName, choices, coins, gained, potions, _ref;
      choices = [];
      for (cardName in state.supply) {
        card = c[cardName];
        _ref = card.getCost(state), coins = _ref[0], potions = _ref[1];
        if (potions === 0 && coins <= 4) {
          choices.push(card);
        }
      }
      gained = state.gainOneOf(state.current, choices);
      if (gained.isAction) {
        state.current.actions += 1;
      }
      if (gained.isTreasure) {
        state.current.coins += 1;
      }
      if (gained.isVictory) {
        return state.current.drawCards(1);
      }
    }
  });
  makeCard('Library', action, {
    cost: 5,
    playEffect: function(state) {
      var card, drawn, player;
      player = state.current;
      while (player.hand.length < 7) {
        drawn = player.getCardsFromDeck(1);
        if (drawn.length === 0) {
          state.log("...stopping because there are no cards to draw.");
          break;
        }
        card = drawn[0];
        if (card.isAction) {
          if (player.ai.choose('discard', state, [card, null])) {
            state.log("" + player.ai + " sets aside a " + card + ".");
            player.setAside.push(card);
          } else {
            state.log("" + player.ai + " draws a " + card + " and chooses to keep it.");
            player.hand.push(card);
          }
        } else {
          state.log("" + player.ai + " draws a " + card + ".");
          player.hand.push(card);
        }
      }
      player.discard = player.discard.concat(player.setAside);
      return player.setAside = [];
    }
  });
  makeCard("Lookout", action, {
    cost: 3,
    actions: +1,
    playEffect: function(state) {
      var discard, drawn, trash;
      drawn = state.getCardsFromDeck(state.current, 3);
      state.log("...drawing " + drawn + ".");
      state.current.setAside = drawn;
      trash = state.current.ai.choose('trash', state, drawn);
      if (trash !== null) {
        state.log("...trashing " + trash + ".");
        state.current.setAside.remove(trash);
      }
      discard = state.current.ai.choose('discard', state, drawn);
      if (discard !== null) {
        transferCard(discard, state.current.setAside, state.current.discard);
        state.log("...discarding " + discard + ".");
      }
      state.log("...putting " + drawn + " back on the deck.");
      state.current.draw = state.current.setAside.concat(state.current.draw);
      return state.current.setAside = [];
    }
  });
  makeCard("Masquerade", action, {
    cost: 3,
    cards: +2,
    playEffect: function(state) {
      var cardToPass, i, nextPlayer, passed, player, _i, _len, _ref, _ref2;
      passed = [];
      _ref = state.players;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        player = _ref[_i];
        cardToPass = player.ai.choose('trash', state, player.hand);
        passed.push(cardToPass);
      }
      for (i = 0, _ref2 = state.nPlayers; 0 <= _ref2 ? i < _ref2 : i > _ref2; 0 <= _ref2 ? i++ : i--) {
        player = state.players[i];
        nextPlayer = state.players[(i + 1) % state.nPlayers];
        cardToPass = passed[i];
        state.log("" + player.ai + " passes " + cardToPass + ".");
        if (cardToPass !== null) {
          transferCard(cardToPass, player.hand, nextPlayer.hand);
        }
      }
      return state.allowTrash(state.current, 1);
    }
  });
  makeCard("Menagerie", action, {
    cost: 3,
    actions: +1,
    playEffect: function(state) {
      state.revealHand(state.current);
      return state.drawCards(state.current, state.current.menagerieDraws());
    }
  });
  makeCard("Mint", action, {
    cost: 5,
    buyEffect: function(state) {
      var i, inPlay, _ref, _results;
      state.quarries = 0;
      state.potions = 0;
      inPlay = state.current.inPlay;
      _results = [];
      for (i = _ref = inPlay.length - 1; _ref <= -1 ? i < -1 : i > -1; _ref <= -1 ? i++ : i--) {
        _results.push(inPlay[i].isTreasure ? (state.log("...trashing a " + inPlay[i] + "."), inPlay.splice(i, 1)) : void 0);
      }
      return _results;
    },
    playEffect: function(state) {
      var card, choice, treasures, _i, _len, _ref;
      treasures = [];
      _ref = state.current.hand;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        if (card.isTreasure) {
          treasures.push(card);
        }
      }
      choice = state.current.ai.choose('mint', state, treasures);
      if (choice !== null) {
        return state.gainCard(state.current, choice);
      }
    }
  });
  makeCard("Moat", action, {
    cost: 2,
    cards: +2,
    isReaction: true,
    attackReaction: function(state, player) {
      return player.moatProtected = true;
    }
  });
  makeCard('Moneylender', action, {
    cost: 4,
    playEffect: function(state) {
      var _ref;
      if (_ref = c.Copper, __indexOf.call(state.current.hand, _ref) >= 0) {
        state.current.doTrash(c.Copper);
        return state.current.coins += 3;
      }
    }
  });
  makeCard("Monument", action, {
    cost: 4,
    coins: 2,
    playEffect: function(state) {
      return state.current.chips += 1;
    }
  });
  makeCard('Pawn', action, {
    cost: 2,
    playEffect: function(state) {
      var benefit;
      benefit = state.current.ai.choose('benefit', state, [
        {
          cards: 1,
          actions: 1
        }, {
          cards: 1,
          buys: 1
        }, {
          cards: 1,
          coins: 1
        }, {
          actions: 1,
          buys: 1
        }, {
          actions: 1,
          coins: 1
        }, {
          buys: 1,
          coins: 1
        }
      ]);
      return applyBenefit(state, benefit);
    }
  });
  makeCard('Peddler', action, {
    cost: 8,
    actions: 1,
    cards: 1,
    coins: 1,
    costInCoins: function(state) {
      var card, cost, _i, _len, _ref;
      cost = 8;
      if (state.phase === 'buy') {
        _ref = state.current.inPlay;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          card = _ref[_i];
          if (card.isAction) {
            cost -= 2;
            if (cost <= 0) {
              break;
            }
          }
        }
      }
      return cost;
    }
  });
  makeCard('Scout', action, {
    cost: 4,
    actions: +1,
    playEffect: function(state) {
      var card, drawn, order, _i, _len;
      drawn = state.getCardsFromDeck(state.current, 4);
      state.log("...drawing " + drawn + ".");
      for (_i = 0, _len = drawn.length; _i < _len; _i++) {
        card = drawn[_i];
        if (card.isVictory) {
          state.current.hand.push(card);
          state.log("...putting " + card + " in the hand.");
        } else {
          state.current.setAside.push(card);
        }
      }
      if (state.current.setAside.length > 0) {
        order = state.current.ai.chooseOrderOnDeck(state, state.current.setAside, state.current);
        state.log("...putting " + order + " back on the deck.");
        state.current.draw = order.concat(state.current.draw);
        return state.current.setAside = [];
      }
    }
  });
  makeCard('Shanty Town', action, {
    cost: 3,
    actions: +2,
    playEffect: function(state) {
      state.revealHand(state.current);
      return state.drawCards(state.current, state.current.shantyTownDraws());
    }
  });
  makeCard('Smugglers', action, {
    cost: 3,
    playEffect: function(state) {
      return state.gainOneOf(state.current, state.smugglerChoices());
    }
  });
  makeCard('Steward', action, {
    cost: 3,
    playEffect: function(state) {
      var benefit;
      benefit = state.current.ai.choose('benefit', state, [
        {
          cards: 2
        }, {
          coins: 2
        }, {
          trash: 2
        }
      ]);
      return applyBenefit(state, benefit);
    }
  });
  makeCard('Tournament', action, {
    cost: 4,
    actions: +1,
    playEffect: function(state) {
      var choice, choices, discardProvince, opp, opposingProvince, _i, _len, _ref, _ref2, _ref3;
      opposingProvince = false;
      _ref = state.players.slice(1);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        opp = _ref[_i];
        if (_ref2 = c.Province, __indexOf.call(opp.hand, _ref2) >= 0) {
          state.log("" + opp.ai + " reveals a Province.");
          opposingProvince = true;
        }
      }
      if (_ref3 = c.Province, __indexOf.call(state.current.hand, _ref3) >= 0) {
        discardProvince = state.current.ai.choose('tournamentDiscard', state, [true, false]);
        if (discardProvince) {
          state.current.doDiscard(c.Province);
          choices = state.prizes.slice(0);
          if (state.supply[c.Duchy] > 0) {
            choices.push(c.Duchy);
          }
          choice = state.gainOneOf(state.current, choices, 'draw');
          if (choice !== null) {
            state.log("...putting the " + choice + " on top of the deck.");
          }
        }
      }
      if (!opposingProvince) {
        state.current.coins += 1;
        return state.current.drawCards(1);
      }
    }
  });
  makeCard("Trade Route", action, {
    cost: 3,
    buys: 1,
    trash: 1,
    getCoins: function(state) {
      return state.tradeRouteValue;
    }
  });
  makeCard("Trading Post", action, {
    cost: 5,
    playEffect: function(state) {
      state.requireTrash(state.current, 2);
      state.gainCard(state.current, c.Silver, 'hand');
      return state.log("...gaining a Silver in hand.");
    }
  });
  makeCard('Treasure Map', action, {
    cost: 4,
    playEffect: function(state) {
      var num, numGolds, trashedMaps, _ref, _ref2;
      trashedMaps = 0;
      if (_ref = c['Treasure Map'], __indexOf.call(state.current.inPlay, _ref) >= 0) {
        state.current.inPlay.remove(c['Treasure Map']);
        state.log("...trashing the Treasure Map.");
        trashedMaps += 1;
      }
      if (_ref2 = c['Treasure Map'], __indexOf.call(state.current.hand, _ref2) >= 0) {
        state.current.doTrash(c['Treasure Map']);
        state.log("...and trashing another Treasure Map.");
        trashedMaps += 1;
      }
      if (trashedMaps === 2) {
        numGolds = 0;
        for (num = 1; num <= 4; num++) {
          if (state.countInSupply(c.Gold) > 0) {
            state.gainCard(state.current, c.Gold, 'draw');
            numGolds += 1;
          }
        }
        return state.log("…gaining " + numGolds + " Golds, putting them on top of the deck.");
      }
    }
  });
  makeCard('Treasury', c.Market, {
    buys: 0,
    buyInPlayEffect: function(state, card) {
      if (card.isVictory) {
        return state.current.mayReturnTreasury = false;
      }
    },
    cleanupEffect: function(state) {
      if (state.current.mayReturnTreasury) {
        transferCardToTop(c.Treasury, state.current.discard, state.current.draw);
        return state.log("" + state.current.ai + " returns a Treasury to the top of the deck.");
      }
    }
  });
  makeCard('Tribute', action, {
    cost: 5,
    playEffect: function(state) {
      var card, revealedCards, unique, _i, _j, _len, _len2, _results;
      revealedCards = state.players[1].discardFromDeck(2);
      unique = [];
      for (_i = 0, _len = revealedCards.length; _i < _len; _i++) {
        card = revealedCards[_i];
        if (__indexOf.call(unique, card) < 0) {
          unique.push(card);
        }
      }
      _results = [];
      for (_j = 0, _len2 = unique.length; _j < _len2; _j++) {
        card = unique[_j];
        if (card.isAction) {
          state.current.actions += 2;
        }
        if (card.isTreasure) {
          state.current.coins += 2;
        }
        _results.push(card.isVictory ? state.current.drawCards(2) : void 0);
      }
      return _results;
    }
  });
  makeCard('University', action, {
    cost: 2,
    costPotion: 1,
    actions: 2,
    playEffect: function(state) {
      var card, cardName, choices, coins, potions, _ref;
      choices = [];
      for (cardName in state.supply) {
        card = c[cardName];
        _ref = card.getCost(state), coins = _ref[0], potions = _ref[1];
        if (potions === 0 && coins <= 5 && card.isAction) {
          choices.push(card);
        }
      }
      return state.gainOneOf(state.current, choices);
    }
  });
  makeCard('Vault', action, {
    cost: 5,
    cards: +2,
    playEffect: function(state) {
      var discarded, opp, _i, _len, _ref, _results;
      discarded = state.allowDiscard(state.current, Infinity);
      state.log("...getting +$" + discarded.length + " from the Vault.");
      state.current.coins += discarded.length;
      _ref = state.players.slice(1);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        opp = _ref[_i];
        _results.push(opp.ai.wantsToDiscard(state) >= 2 ? (discarded = state.requireDiscard(opp, 2), discarded.length === 2 ? state.drawCards(opp, 1) : void 0) : void 0);
      }
      return _results;
    }
  });
  makeCard('Walled Village', c.Village, {
    cost: 4
  });
  makeCard('Warehouse', action, {
    cost: 3,
    actions: +1,
    playEffect: function(state) {
      state.drawCards(state.current, 3);
      return state.requireDiscard(state.current, 3);
    }
  });
  makeCard('Watchtower', action, {
    cost: 3,
    isReaction: true,
    playEffect: function(state) {
      var handLength;
      handLength = state.current.hand.length;
      if (handLength < 6) {
        return state.drawCards(state.current, 6 - handLength);
      }
    },
    gainReaction: function(state, player, card) {
      var source;
      if (player.gainLocation === 'trash') {
        return;
      }
      source = player[player.gainLocation];
      if (player.ai.chooseTrash(state, [card, null]) === card) {
        state.log("" + player.ai + " reveals a Watchtower and trashes the " + card + ".");
        source.remove(card);
        return player.gainLocation = 'trash';
      } else if (player.ai.choose('gainOnDeck', state, [card, null])) {
        state.log("" + player.ai + " reveals a Watchtower and puts the " + card + " on the deck.");
        player.gainLocation = 'draw';
        return transferCardToTop(card, source, player.draw);
      }
    }
  });
  makeCard('Wishing Well', action, {
    cost: 3,
    cards: 1,
    actions: 1,
    playEffect: function(state) {
      var card, cardName, choices, drawn, wish, _i, _len, _ref;
      choices = [];
      _ref = c.allCards;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cardName = _ref[_i];
        choices.push(c[cardName]);
      }
      wish = state.current.ai.choose('wish', state, choices);
      state.log("...wishing for a " + wish + ".");
      drawn = state.current.getCardsFromDeck(1);
      if (drawn.length > 0) {
        card = drawn[0];
        if (card === wish) {
          state.log("...revealing a " + card + " and keeping it.");
          return state.current.hand.push(card);
        } else {
          state.log("...revealing a " + card + " and putting it back.");
          return state.current.draw.unshift(card);
        }
      } else {
        return state.log("...drawing nothing.");
      }
    }
  });
  makeCard('Workshop', action, {
    cost: 3,
    playEffect: function(state) {
      var card, cardName, choices, coins, potions, _ref;
      choices = [];
      for (cardName in state.supply) {
        card = c[cardName];
        _ref = card.getCost(state), coins = _ref[0], potions = _ref[1];
        if (potions === 0 && coins <= 4) {
          choices.push(card);
        }
      }
      return state.gainOneOf(state.current, choices);
    }
  });
  transferCard = function(card, fromList, toList) {
    if (__indexOf.call(fromList, card) < 0) {
      throw new Error("" + fromList + " does not contain " + card);
    }
    fromList.remove(card);
    return toList.push(card);
  };
  transferCardToTop = function(card, fromList, toList) {
    if (__indexOf.call(fromList, card) < 0) {
      throw new Error("" + fromList + " does not contain " + card);
    }
    fromList.remove(card);
    return toList.unshift(card);
  };
  applyBenefit = function(state, benefit) {
    var i;
    state.log("" + state.current.ai + " chooses " + (JSON.stringify(benefit)) + ".");
    if (benefit.cards != null) {
      state.drawCards(state.current, benefit.cards);
    }
    if (benefit.actions != null) {
      state.current.actions += benefit.actions;
    }
    if (benefit.buys != null) {
      state.current.buys += benefit.buys;
    }
    if (benefit.coins != null) {
      state.current.coins += benefit.coins;
    }
    if (benefit.trash != null) {
      state.requireTrash(state.current, benefit.trash);
    }
    if (benefit.horseEffect) {
      for (i = 0; i < 4; i++) {
        state.gainCard(state.current, c.Silver);
      }
      state.current.discard = state.current.discard.concat(state.current.draw);
      return state.current.draw = [];
    }
  };
  upgradeChoices = function(state, cards, filter) {
    var card, card2, cardname2, choices, used, _i, _len;
    used = [];
    choices = [];
    for (_i = 0, _len = cards.length; _i < _len; _i++) {
      card = cards[_i];
      if (__indexOf.call(used, card) < 0) {
        used.push(card);
        for (cardname2 in state.supply) {
          card2 = c[cardname2];
          if (filter(state, card, card2) && state.supply[card2] > 0) {
            choices.push([card, card2]);
          }
        }
      }
    }
    return choices;
  };
  this.transferCard = transferCard;
  this.transferCardToTop = transferCardToTop;
  if (typeof exports !== "undefined" && exports !== null) {
    _ref = require('./cards'), c = _ref.c, transferCard = _ref.transferCard, transferCardToTop = _ref.transferCardToTop;
  }
  PlayerState = (function() {
    function PlayerState() {}
    PlayerState.prototype.initialize = function(ai, logFunc) {
      this.actions = 1;
      this.buys = 1;
      this.coins = 0;
      this.potions = 0;
      this.mats = {
        pirateShip: 0,
        nativeVillage: [],
        island: []
      };
      this.setAsideByHaven = [];
      this.chips = 0;
      this.hand = [];
      this.discard = [c.Copper, c.Copper, c.Copper, c.Copper, c.Copper, c.Copper, c.Copper, c.Estate, c.Estate, c.Estate];
      this.draw = [];
      this.inPlay = [];
      this.duration = [];
      this.setAside = [];
      this.gainedThisTurn = [];
      this.moatProtected = false;
      this.tacticians = 0;
      this.mayReturnTreasury = true;
      this.turnsTaken = 0;
      this.playLocation = 'inPlay';
      this.gainLocation = 'discard';
      this.actionStack = [];
      this.ai = ai;
      this.logFunc = logFunc;
      this.drawCards(5);
      return this;
    };
    PlayerState.prototype.getDeck = function() {
      return this.draw.concat(this.discard.concat(this.hand.concat(this.inPlay.concat(this.duration.concat(this.mats.nativeVillage.concat(this.mats.island.concat(this.setAsideByHaven)))))));
    };
    PlayerState.prototype.getCurrentAction = function() {
      return this.actionStack[this.actionStack.length - 1];
    };
    PlayerState.prototype.countInDeck = function(card) {
      var card2, count, _i, _len, _ref2;
      count = 0;
      _ref2 = this.getDeck();
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card2 = _ref2[_i];
        if (card.toString() === card2.toString()) {
          count++;
        }
      }
      return count;
    };
    PlayerState.prototype.numCardsInDeck = function() {
      return this.getDeck().length;
    };
    PlayerState.prototype.countCardTypeInDeck = function(type) {
      var card, count, typeChecker, _i, _len, _ref2;
      typeChecker = 'is' + type;
      count = 0;
      _ref2 = this.getDeck();
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card = _ref2[_i];
        if (card[typeChecker]) {
          count++;
        }
      }
      return count;
    };
    PlayerState.prototype.getVP = function(state) {
      var card, total, _i, _len, _ref2;
      total = this.chips;
      _ref2 = this.getDeck();
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card = _ref2[_i];
        total += card.getVP(state);
      }
      return total;
    };
    PlayerState.prototype.getTotalMoney = function() {
      var card, total, _i, _len, _ref2;
      total = 0;
      _ref2 = this.getDeck();
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card = _ref2[_i];
        total += card.coins;
      }
      return total;
    };
    PlayerState.prototype.getAvailableMoney = function() {
      return this.coins + this.getTreasureInHand();
    };
    PlayerState.prototype.getTreasureInHand = function() {
      var card, total, _i, _len, _ref2;
      total = 0;
      _ref2 = this.hand;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card = _ref2[_i];
        if (card.isTreasure) {
          total += card.coins;
        }
      }
      return total;
    };
    PlayerState.prototype.countPlayableTerminals = function(state) {
      var card;
      if (this.actions > 0) {
        return this.actions + (((function() {
          var _i, _len, _ref2, _results;
          _ref2 = this.hand;
          _results = [];
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            card = _ref2[_i];
            _results.push(Math.max(card.getActions(state) - 1, 0));
          }
          return _results;
        }).call(this)).reduce(function(s, t) {
          return s + t;
        }));
      } else {
        return 0;
      }
    };
    PlayerState.prototype.countInHand = function(card) {
      return countStr(this.hand, card);
    };
    PlayerState.prototype.countInDiscard = function(card) {
      return countStr(this.discard, card);
    };
    PlayerState.prototype.countInPlay = function(card) {
      return countStr(this.inPlay, card);
    };
    PlayerState.prototype.numActionCardsInDeck = function() {
      var card, count, _i, _len, _ref2;
      count = 0;
      _ref2 = this.getDeck();
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card = _ref2[_i];
        if (card.isAction) {
          count += 1;
        }
      }
      return count;
    };
    PlayerState.prototype.getActionDensity = function() {
      return this.numActionCardsInDeck() / this.getDeck().length;
    };
    PlayerState.prototype.menagerieDraws = function() {
      var card, cardsToDraw, seen, _i, _len, _ref2;
      seen = {};
      cardsToDraw = 3;
      _ref2 = this.hand;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card = _ref2[_i];
        if (seen[card.name] != null) {
          cardsToDraw = 1;
          break;
        }
        seen[card.name] = true;
      }
      return cardsToDraw;
    };
    PlayerState.prototype.shantyTownDraws = function(hypothetical) {
      var card, cardsToDraw, skippedShanty, _i, _len, _ref2;
      if (hypothetical == null) {
        hypothetical = false;
      }
      cardsToDraw = 2;
      skippedShanty = false;
      _ref2 = this.hand;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card = _ref2[_i];
        if (card.isAction) {
          if (hypothetical && !skippedShanty) {
            skippedShanty = true;
          } else {
            cardsToDraw = 0;
            break;
          }
        }
      }
      return cardsToDraw;
    };
    PlayerState.prototype.actionBalance = function() {
      var balance, card, _i, _len, _ref2;
      balance = this.actions;
      _ref2 = this.hand;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card = _ref2[_i];
        if (card.isAction) {
          balance += card.actions;
          balance--;
          if (card.actions === 0) {
            balance -= card.cards * this.getActionDensity();
          }
        }
      }
      return balance;
    };
    PlayerState.prototype.trashingInHand = function() {
      var card, trash, _i, _len, _ref2;
      trash = 0;
      _ref2 = this.hand;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card = _ref2[_i];
        trash += card.trash;
        if (card === c.Steward) {
          trash += 2;
        }
        if (card === c['Trading Post']) {
          trash += 2;
        }
        if (card === c.Chapel) {
          trash += 4;
        }
        if (card === c.Masquerade) {
          trash += 1;
        }
        if (card === c.Ambassador) {
          trash += 2;
        }
        if (card === c.Watchtower) {
          trash += 1;
        }
      }
      return trash;
    };
    PlayerState.prototype.numUniqueCardsInPlay = function() {
      var card, cards, unique, _i, _len;
      unique = [];
      cards = this.inPlay.concat(this.duration);
      for (_i = 0, _len = cards.length; _i < _len; _i++) {
        card = cards[_i];
        if (__indexOf.call(unique, card) < 0) {
          unique.push(card);
        }
      }
      return unique.length;
    };
    PlayerState.prototype.drawCards = function(nCards) {
      var drawn;
      drawn = this.getCardsFromDeck(nCards);
      this.hand = this.hand.concat(drawn);
      this.log("" + this.ai + " draws " + drawn.length + " cards (" + drawn + ").");
      return drawn;
    };
    PlayerState.prototype.discardFromDeck = function(nCards) {
      var drawn;
      drawn = this.getCardsFromDeck(nCards);
      this.discard = this.discard.concat(drawn);
      this.log("" + this.ai + " draws and discards " + drawn.length + " cards (" + drawn + ").");
      return drawn;
    };
    PlayerState.prototype.getCardsFromDeck = function(nCards) {
      var diff, drawn;
      if (this.draw.length < nCards) {
        diff = nCards - this.draw.length;
        drawn = this.draw.slice(0);
        this.draw = [];
        if (this.discard.length > 0) {
          this.shuffle();
          return drawn.concat(this.getCardsFromDeck(diff));
        } else {
          return drawn;
        }
      } else {
        drawn = this.draw.slice(0, nCards);
        this.draw = this.draw.slice(nCards);
        return drawn;
      }
    };
    PlayerState.prototype.dig = function(state, digFunc, nCards, discardSetAside) {
      var card, drawn, foundCards, revealedCards;
      if (nCards == null) {
        nCards = 1;
      }
      if (discardSetAside == null) {
        discardSetAside = true;
      }
      foundCards = [];
      revealedCards = [];
      while (foundCards.length < nCards) {
        drawn = this.getCardsFromDeck(1);
        if (drawn.length === 0) {
          break;
        }
        card = drawn[0];
        revealedCards.push(card);
        if (digFunc(state, card)) {
          foundCards.push(card);
        } else {
          this.setAside.push(card);
        }
      }
      if (revealedCards.length === 0) {
        this.log("..." + this.ai + " has no cards to draw.");
      } else {
        this.log("..." + this.ai + " reveals " + revealedCards + ".");
      }
      if (discardSetAside) {
        if (this.setAside.length > 0) {
          this.log("..." + this.ai + " discards " + this.setAside + ".");
        }
        this.discard = this.discard.concat(this.setAside);
        this.setAside = [];
      }
      return foundCards;
    };
    PlayerState.prototype.doDiscard = function(card) {
      if (__indexOf.call(this.hand, card) < 0) {
        this.warn("" + this.ai + " has no " + card + " to discard");
        return;
      }
      this.log("" + this.ai + " discards " + card + ".");
      this.hand.remove(card);
      return this.discard.push(card);
    };
    PlayerState.prototype.doTrash = function(card) {
      if (__indexOf.call(this.hand, card) < 0) {
        this.warn("" + this.ai + " has no " + card + " to trash");
        return;
      }
      this.log("" + this.ai + " trashes " + card + ".");
      return this.hand.remove(card);
    };
    PlayerState.prototype.doPutOnDeck = function(card) {
      if (__indexOf.call(this.hand, card) < 0) {
        this.warn("" + this.ai + " has no " + card + " to put on deck.");
        return;
      }
      this.log("" + this.ai + " puts " + card + " on deck.");
      this.hand.remove(card);
      return this.draw.unshift(card);
    };
    PlayerState.prototype.shuffle = function() {
      this.log("(" + this.ai + " shuffles.)");
      if (this.draw.length > 0) {
        throw new Error("Shuffling while there are cards left to draw");
      }
      shuffle(this.discard);
      this.draw = this.discard;
      return this.discard = [];
    };
    PlayerState.prototype.copy = function() {
      var other;
      other = new PlayerState();
      other.actions = this.actions;
      other.buys = this.buys;
      other.coins = this.coins;
      other.potions = this.potions;
      other.setAsideByHaven = this.setAsideByHaven.slice(0);
      other.mats = {};
      other.mats.pirateShip = this.mats.pirateShip;
      other.mats.nativeVillage = this.mats.nativeVillage.slice(0);
      other.mats.island = this.mats.island.slice(0);
      other.chips = this.chips;
      other.hand = this.hand.slice(0);
      other.draw = this.draw.slice(0);
      other.discard = this.discard.slice(0);
      other.inPlay = this.inPlay.slice(0);
      other.duration = this.duration.slice(0);
      other.setAside = this.setAside.slice(0);
      other.moatProtected = this.moatProtected;
      other.gainedThisTurn = this.gainedThisTurn.slice(0);
      other.mayReturnTreasury = this.mayReturnTreasury;
      other.playLocation = this.playLocation;
      other.gainLocation = this.gainLocation;
      other.actionStack = this.actionStack.slice(0);
      other.tacticians = this.tacticians;
      other.ai = this.ai;
      other.logFunc = this.logFunc;
      other.turnsTaken = this.turnsTaken;
      return other;
    };
    PlayerState.prototype.log = function(obj) {
      if (this.logFunc != null) {
        return this.logFunc(obj);
      } else {
        if (typeof console !== "undefined" && console !== null) {
          return console.log(obj);
        }
      }
    };
    return PlayerState;
  })();
  State = (function() {
    function State() {}
    State.prototype.basicSupply = ['Curse', 'Copper', 'Silver', 'Gold', 'Estate', 'Duchy', 'Province'];
    State.prototype.cardInfo = c;
    State.prototype.initialize = function(ais, tableau, logFunc) {
      var ai;
      this.logFunc = logFunc;
      this.players = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = ais.length; _i < _len; _i++) {
          ai = ais[_i];
          _results.push(new PlayerState().initialize(ai, this.logFunc));
        }
        return _results;
      }).call(this);
      this.nPlayers = this.players.length;
      this.current = this.players[0];
      this.supply = this.makeSupply(tableau);
      this.prizes = [c["Bag of Gold"], c.Diadem, c.Followers, c.Princess, c["Trusty Steed"]];
      this.tradeRouteMat = [];
      this.tradeRouteValue = 0;
      this.bridges = 0;
      this.princesses = 0;
      this.quarries = 0;
      this.copperValue = 1;
      this.phase = 'start';
      this.extraturn = false;
      this.cache = {};
      this.depth = 0;
      return this;
    };
    State.prototype.makeSupply = function(tableau) {
      var allCards, card, supply, _i, _len, _ref2;
      allCards = this.basicSupply.concat(tableau);
      supply = {};
      for (_i = 0, _len = allCards.length; _i < _len; _i++) {
        card = allCards[_i];
        if (c[card].startingSupply(this) > 0) {
          card = (_ref2 = c[card]) != null ? _ref2 : card;
          supply[card] = card.startingSupply(this);
        }
      }
      return supply;
    };
    State.prototype.emptyPiles = function() {
      var key, piles, value, _ref2;
      piles = [];
      _ref2 = this.supply;
      for (key in _ref2) {
        value = _ref2[key];
        if (value === 0) {
          piles.push(key);
        }
      }
      return piles;
    };
    State.prototype.numEmptyPiles = function() {
      return this.emptyPiles().length;
    };
    State.prototype.gameIsOver = function() {
      var emptyPiles, playerName, turns, vp, _i, _len, _ref2, _ref3;
      if (this.phase !== 'start') {
        return false;
      }
      emptyPiles = this.emptyPiles();
      if (emptyPiles.length >= this.totalPilesToEndGame() || (this.nPlayers < 5 && emptyPiles.length >= 3) || __indexOf.call(emptyPiles, 'Province') >= 0 || __indexOf.call(emptyPiles, 'Colony') >= 0) {
        this.log("Empty piles: " + emptyPiles);
        _ref2 = this.getFinalStatus();
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          _ref3 = _ref2[_i], playerName = _ref3[0], vp = _ref3[1], turns = _ref3[2];
          this.log("" + playerName + " took " + turns + " turns and scored " + vp + " points.");
        }
        return true;
      }
      return false;
    };
    State.prototype.getFinalStatus = function() {
      var player, _i, _len, _ref2, _results;
      _ref2 = this.players;
      _results = [];
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        player = _ref2[_i];
        _results.push([player.ai.toString(), player.getVP(this), player.turnsTaken]);
      }
      return _results;
    };
    State.prototype.getWinners = function() {
      var best, bestScore, modScore, player, score, scores, turns, _i, _len, _ref2;
      scores = this.getFinalStatus();
      best = [];
      bestScore = -Infinity;
      for (_i = 0, _len = scores.length; _i < _len; _i++) {
        _ref2 = scores[_i], player = _ref2[0], score = _ref2[1], turns = _ref2[2];
        modScore = score - turns / 100;
        if (modScore === bestScore) {
          best.push(player);
        }
        if (modScore > bestScore) {
          best = [player];
          bestScore = modScore;
        }
      }
      return best;
    };
    State.prototype.countInSupply = function(card) {
      var _ref2;
      return (_ref2 = this.supply[card]) != null ? _ref2 : 0;
    };
    State.prototype.totalPilesToEndGame = function() {
      switch (this.nPlayers) {
        case 1:
        case 2:
        case 3:
        case 4:
          return 3;
        default:
          return 4;
      }
    };
    State.prototype.gainsToEndGame = function() {
      var card, count, counts, minimum, piles, _i, _len, _ref2;
      if (this.cache.gainsToEndGame != null) {
        return this.cache.gainsToEndGame;
      }
      counts = (function() {
        var _ref2, _results;
        _ref2 = this.supply;
        _results = [];
        for (card in _ref2) {
          count = _ref2[card];
          _results.push(count);
        }
        return _results;
      }).call(this);
      numericSort(counts);
      piles = this.totalPilesToEndGame();
      minimum = 0;
      _ref2 = counts.slice(0, piles);
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        count = _ref2[_i];
        minimum += count;
      }
      minimum = Math.min(minimum, this.supply['Province']);
      if (this.supply['Colony'] != null) {
        minimum = Math.min(minimum, this.supply['Colony']);
      }
      this.cache.gainsToEndGame = minimum;
      return minimum;
    };
    State.prototype.smugglerChoices = function() {
      var card, choices, coins, potions, prevPlayer, _i, _len, _ref2, _ref3;
      choices = [null];
      prevPlayer = this.players[this.nPlayers - 1];
      _ref2 = prevPlayer.gainedThisTurn;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card = _ref2[_i];
        _ref3 = card.getCost(this), coins = _ref3[0], potions = _ref3[1];
        if (potions === 0 && coins <= 6) {
          choices.push(card);
        }
      }
      return choices;
    };
    State.prototype.doPlay = function() {
      switch (this.phase) {
        case 'start':
          if (!this.extraturn) {
            this.current.turnsTaken += 1;
            this.log("\n== " + this.current.ai + "'s turn " + this.current.turnsTaken + " ==");
            this.doDurationPhase();
            return this.phase = 'action';
          } else {
            this.log("\n== " + this.current.ai + "'s turn " + this.current.turnsTaken + "+ ==");
            this.doDurationPhase();
            return this.phase = 'action';
          }
          break;
        case 'action':
          this.doActionPhase();
          return this.phase = 'treasure';
        case 'treasure':
          this.doTreasurePhase();
          return this.phase = 'buy';
        case 'buy':
          this.doBuyPhase();
          return this.phase = 'cleanup';
        case 'cleanup':
          this.doCleanupPhase();
          if (!this.extraturn) {
            return this.rotatePlayer();
          } else {
            return this.phase = 'start';
          }
      }
    };
    State.prototype.doDurationPhase = function() {
      var card, estimatedBuys, i, _ref2, _results;
      this.current.gainedThisTurn = [];
      if (this.depth === 0 && (this.debug != null)) {
        estimatedBuys = this.current.ai.pessimisticCardsGained(this);
        this.log("" + this.current.ai + " plans to buy " + estimatedBuys + ".");
      }
      _results = [];
      for (i = _ref2 = this.current.duration.length - 1; _ref2 <= -1 ? i < -1 : i > -1; _ref2 <= -1 ? i++ : i--) {
        card = this.current.duration[i];
        this.log("" + this.current.ai + " resolves the duration effect of " + card + ".");
        _results.push(card.onDuration(this));
      }
      return _results;
    };
    State.prototype.doActionPhase = function() {
      var card, validActions, _i, _len, _ref2, _results;
      _results = [];
      while (this.current.actions > 0) {
        validActions = [null];
        _ref2 = this.current.hand;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          card = _ref2[_i];
          if (card.isAction && __indexOf.call(validActions, card) < 0) {
            validActions.push(card);
          }
        }
        action = this.current.ai.chooseAction(this, validActions);
        if (action === null) {
          return;
        }
        if (__indexOf.call(this.current.hand, action) < 0) {
          this.warn("" + this.current.ai + " chose an invalid action.");
          return;
        }
        _results.push(this.playAction(action));
      }
      return _results;
    };
    State.prototype.playAction = function(action) {
      this.log("" + this.current.ai + " plays " + action + ".");
      this.current.hand.remove(action);
      this.current.inPlay.push(action);
      this.current.playLocation = 'inPlay';
      this.current.actions -= 1;
      return this.resolveAction(action);
    };
    State.prototype.resolveAction = function(action) {
      this.current.actionStack.push(action);
      action.onPlay(this);
      return this.current.actionStack.pop();
    };
    State.prototype.doTreasurePhase = function() {
      var card, validTreasures, _i, _len, _ref2, _results;
      _results = [];
      while (true) {
        validTreasures = [null];
        _ref2 = this.current.hand;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          card = _ref2[_i];
          if (card.isTreasure && __indexOf.call(validTreasures, card) < 0) {
            validTreasures.push(card);
          }
        }
        treasure = this.current.ai.chooseTreasure(this, validTreasures);
        if (treasure === null) {
          return;
        }
        this.log("" + this.current.ai + " plays " + treasure + ".");
        if (__indexOf.call(this.current.hand, treasure) < 0) {
          this.warn("" + this.current.ai + " chose an invalid treasure");
          return;
        }
        _results.push(this.playTreasure(treasure));
      }
      return _results;
    };
    State.prototype.playTreasure = function(treasure) {
      this.current.hand.remove(treasure);
      this.current.inPlay.push(treasure);
      this.current.playLocation = 'inPlay';
      return treasure.onPlay(this);
    };
    State.prototype.getSingleBuyDecision = function() {
      var buyable, card, cardname, choice, coinCost, count, potionCost, _ref2, _ref3;
      buyable = [null];
      _ref2 = this.supply;
      for (cardname in _ref2) {
        count = _ref2[cardname];
        card = c[cardname];
        if (card.mayBeBought(this) && count > 0) {
          _ref3 = card.getCost(this), coinCost = _ref3[0], potionCost = _ref3[1];
          if (coinCost <= this.current.coins && potionCost <= this.current.potions) {
            buyable.push(card);
          }
        }
      }
      this.log("Coins: " + this.current.coins + ", Potions: " + this.current.potions + ", Buys: " + this.current.buys);
      choice = this.current.ai.chooseGain(this, buyable);
      return choice;
    };
    State.prototype.doBuyPhase = function() {
      var cardInPlay, choice, coinCost, goonses, i, potionCost, _ref2, _ref3, _results;
      _results = [];
      while (this.current.buys > 0) {
        choice = this.getSingleBuyDecision();
        if (choice === null) {
          return;
        }
        this.log("" + this.current.ai + " buys " + choice + ".");
        _ref2 = choice.getCost(this), coinCost = _ref2[0], potionCost = _ref2[1];
        this.current.coins -= coinCost;
        this.current.potions -= potionCost;
        this.current.buys -= 1;
        this.gainCard(this.current, choice, 'discard', true);
        choice.onBuy(this);
        for (i = _ref3 = this.current.inPlay.length - 1; _ref3 <= -1 ? i < -1 : i > -1; _ref3 <= -1 ? i++ : i--) {
          cardInPlay = this.current.inPlay[i];
          cardInPlay.buyInPlayEffect(this, choice);
        }
        goonses = this.current.countInPlay('Goons');
        _results.push(goonses > 0 ? (this.log("...gaining " + goonses + " VP."), this.current.chips += goonses) : void 0);
      }
      return _results;
    };
    State.prototype.doCleanupPhase = function() {
      var actionCardsInPlay, card, _i, _len, _ref2, _ref3, _ref4, _ref5;
      actionCardsInPlay = 0;
      _ref2 = this.current.inPlay;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        card = _ref2[_i];
        if (card.isAction) {
          actionCardsInPlay += 1;
        }
      }
      if (actionCardsInPlay <= 2) {
        while (_ref3 = c['Walled Village'], __indexOf.call(this.current.inPlay, _ref3) >= 0) {
          transferCardToTop(c['Walled Village'], this.current.inPlay, this.current.draw);
          this.log("" + this.current.ai + " returns a Walled Village to the top of the deck.");
        }
      }
      this.extraturn = !this.extraturn && (_ref4 = c['Outpost'], __indexOf.call(this.current.inPlay, _ref4) >= 0);
      this.current.discard = this.current.discard.concat(this.current.duration);
      this.current.duration = [];
      if (this.current.setAside.length > 0) {
        this.warn(["Cards were set aside at the end of turn", this.current.setAside]);
        this.current.discard = this.current.discard.concat(this.current.setAside);
        this.current.setAside = [];
      }
      while (this.current.inPlay.length > 0) {
        card = this.current.inPlay[0];
        this.current.inPlay = this.current.inPlay.slice(1);
        if (card.isDuration) {
          this.current.duration.push(card);
        } else {
          this.current.discard.push(card);
        }
        card.onCleanup(this);
      }
      this.current.discard = this.current.discard.concat(this.current.hand);
      this.current.hand = [];
      this.current.actions = 1;
      this.current.buys = 1;
      this.current.coins = 0;
      this.current.potions = 0;
      this.current.tacticians = 0;
      this.current.mayReturnTreasury = true;
      this.copperValue = 1;
      this.bridges = 0;
      this.princesses = 0;
      this.quarries = 0;
      if (this.extraturn) {
        this.log("" + this.current.ai + " takes an extra turn from Outpost.");
      }
      if (!(_ref5 = c.Outpost, __indexOf.call(this.current.duration, _ref5) >= 0)) {
        return this.current.drawCards(5);
      } else {
        return this.current.drawCards(3);
      }
    };
    State.prototype.rotatePlayer = function() {
      this.players = this.players.slice(1, this.nPlayers).concat([this.players[0]]);
      this.current = this.players[0];
      return this.phase = 'start';
    };
    State.prototype.gainCard = function(player, card, gainLocation, suppressMessage) {
      var cardInPlay, i, location, reactCard, _ref2, _ref3, _results;
      if (gainLocation == null) {
        gainLocation = 'discard';
      }
      if (suppressMessage == null) {
        suppressMessage = false;
      }
      delete this.cache.gainsToEndGame;
      if (__indexOf.call(this.prizes, card) >= 0 || this.supply[card] > 0) {
        if (player === this.current) {
          player.gainedThisTurn.push(card);
        }
        if (!suppressMessage) {
          this.log("" + player.ai + " gains " + card + ".");
        }
        player.gainLocation = gainLocation;
        location = player[player.gainLocation];
        location.unshift(card);
        if (__indexOf.call(this.prizes, card) >= 0) {
          this.prizes.remove(card);
        } else {
          this.supply[card] -= 1;
        }
        if ((this.supply["Trade Route"] != null) && card.isVictory && __indexOf.call(this.tradeRouteMat, card) < 0) {
          this.tradeRouteMat.push(card);
          this.tradeRouteValue += 1;
        }
        for (i = _ref2 = player.inPlay.length - 1; _ref2 <= -1 ? i < -1 : i > -1; _ref2 <= -1 ? i++ : i--) {
          cardInPlay = player.inPlay[i];
          cardInPlay.gainInPlayEffect(this, card);
        }
        _results = [];
        for (i = _ref3 = player.hand.length - 1; _ref3 <= -1 ? i < -1 : i > -1; _ref3 <= -1 ? i++ : i--) {
          reactCard = player.hand[i];
          _results.push(reactCard.isReaction ? reactCard.reactToGain(this, player, card) : void 0);
        }
        return _results;
      } else {
        return this.log("There is no " + card + " to gain.");
      }
    };
    State.prototype.revealHand = function(player) {
      return this.log("" + player.ai + " reveals the hand (" + player.hand + ").");
    };
    State.prototype.drawCards = function(player, num) {
      return player.drawCards(num);
    };
    State.prototype.discardFromDeck = function(player, num) {
      return player.discardFromDeck(num);
    };
    State.prototype.getCardsFromDeck = function(player, num) {
      return player.getCardsFromDeck(num);
    };
    State.prototype.allowDiscard = function(player, num) {
      var choice, discarded, validDiscards;
      discarded = [];
      while (discarded.length < num) {
        validDiscards = player.hand.slice(0);
        validDiscards.push(null);
        choice = player.ai.chooseDiscard(this, validDiscards);
        if (choice === null) {
          return discarded;
        }
        discarded.push(choice);
        player.doDiscard(choice);
      }
      return discarded;
    };
    State.prototype.requireDiscard = function(player, num) {
      var choice, discarded, validDiscards;
      discarded = [];
      while (discarded.length < num) {
        validDiscards = player.hand.slice(0);
        if (validDiscards.length === 0) {
          return discarded;
        }
        choice = player.ai.chooseDiscard(this, validDiscards);
        discarded.push(choice);
        player.doDiscard(choice);
      }
      return discarded;
    };
    State.prototype.allowTrash = function(player, num) {
      var choice, trashed, valid;
      trashed = [];
      while (trashed.length < num) {
        valid = player.hand.slice(0);
        valid.push(null);
        choice = player.ai.chooseTrash(this, valid);
        if (choice === null) {
          return trashed;
        }
        trashed.push(choice);
        player.doTrash(choice);
      }
      return trashed;
    };
    State.prototype.requireTrash = function(player, num) {
      var choice, trashed, valid;
      trashed = [];
      while (trashed.length < num) {
        valid = player.hand.slice(0);
        if (valid.length === 0) {
          return trashed;
        }
        choice = player.ai.chooseTrash(this, valid);
        trashed.push(choice);
        player.doTrash(choice);
      }
      return trashed;
    };
    State.prototype.gainOneOf = function(player, options, location) {
      var choice;
      if (location == null) {
        location = 'discard';
      }
      choice = player.ai.chooseGain(this, options);
      if (choice === null) {
        return null;
      }
      this.gainCard(player, choice, location);
      return choice;
    };
    State.prototype.attackOpponents = function(effect) {
      var opp, _i, _len, _ref2, _results;
      _ref2 = this.players.slice(1);
      _results = [];
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        opp = _ref2[_i];
        _results.push(this.attackPlayer(opp, effect));
      }
      return _results;
    };
    State.prototype.attackPlayer = function(player, effect) {
      var card, i, _ref2, _ref3;
      player.moatProtected = false;
      for (i = _ref2 = player.hand.length - 1; _ref2 <= -1 ? i < -1 : i > -1; _ref2 <= -1 ? i++ : i--) {
        card = player.hand[i];
        if (card.isReaction) {
          card.reactToAttack(this, player);
        }
      }
      if (player.moatProtected) {
        return this.log("" + player.ai + " is protected by a Moat.");
      } else if (_ref3 = c.Lighthouse, __indexOf.call(player.duration, _ref3) >= 0) {
        return this.log("" + player.ai + " is protected by the Lighthouse.");
      } else {
        return effect(player);
      }
    };
    State.prototype.copy = function() {
      var key, newPlayers, newState, newSupply, player, playerCopy, value, _i, _len, _ref2, _ref3;
      newSupply = {};
      _ref2 = this.supply;
      for (key in _ref2) {
        value = _ref2[key];
        newSupply[key] = value;
      }
      newState = new State();
      newState.logFunc = this.logFunc;
      newPlayers = [];
      _ref3 = this.players;
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        player = _ref3[_i];
        playerCopy = player.copy();
        playerCopy.logFunc = function(obj) {};
        newPlayers.push(playerCopy);
      }
      newState.players = newPlayers;
      newState.supply = newSupply;
      newState.current = newPlayers[0];
      newState.nPlayers = this.nPlayers;
      newState.tradeRouteMat = this.tradeRouteMat.slice(0);
      newState.tradeRouteValue = this.tradeRouteValue;
      newState.bridges = this.bridges;
      newState.princesses = this.princesses;
      newState.quarries = this.quarries;
      newState.copperValue = this.copperValue;
      newState.phase = this.phase;
      newState.cache = {};
      newState.prizes = this.prizes.slice(0);
      return newState;
    };
    State.prototype.hypothetical = function(ai) {
      var combined, handSize, my, player, state, _i, _len, _ref2;
      state = this.copy();
      state.depth = this.depth + 1;
      my = null;
      _ref2 = state.players;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        player = _ref2[_i];
        if (player.ai !== ai) {
          player.ai = ai.copy();
          handSize = player.hand.length;
          combined = player.hand.concat(player.draw);
          shuffle(combined);
          player.hand = combined.slice(0, handSize);
          player.draw = combined.slice(handSize);
        } else {
          shuffle(player.draw);
          my = player;
        }
      }
      return [state, my];
    };
    State.prototype.compareByActionPriority = function(state, my, x, y) {
      my.ai.cacheActionPriority(state, my);
      return my.ai.choiceToValue('cachedAction', state, x) - my.ai.choiceToValue('cachedAction', state, y);
    };
    State.prototype.compareByCoinCost = function(state, my, x, y) {
      return x.getCost(state)[0] - y.getCost(state)[0];
    };
    State.prototype.log = function(obj) {
      if (this.depth === 0) {
        if (this.logFunc != null) {
          return this.logFunc(obj);
        } else {
          if (typeof console !== "undefined" && console !== null) {
            return console.log(obj);
          }
        }
      }
    };
    State.prototype.warn = function(obj) {
      if (typeof console !== "undefined" && console !== null) {
        return console.warn("WARNING: ", obj);
      }
    };
    return State;
  })();
  this.tableaux = {
    moneyOnly: [],
    moneyOnlyColony: ['Platinum', 'Colony'],
    all: c.allCards
  };
  Array.prototype.remove = function(elt) {
    var idx;
    idx = this.lastIndexOf(elt);
    if (idx !== -1) {
      return this.splice(idx, 1);
    } else {
      return [];
    }
  };
  noColony = this.tableaux.all.slice(0);
  noColony.remove('Platinum');
  noColony.remove('Colony');
  this.tableaux.noColony = noColony;
  cloneDominionObject = function(obj) {
    var key, newInstance, value;
    if (!(obj != null) || typeof obj !== 'object') {
      return obj;
    }
    if ((obj.gainPriority != null) || (obj.costInCoins != null)) {
      return obj;
    }
    newInstance = new obj.constructor();
    for (key in obj) {
      if (!__hasProp.call(obj, key)) continue;
      value = obj[key];
      newInstance[key] = cloneDominionObject(value);
    }
    return newInstance;
  };
  shuffle = function(v) {
    var i, j, temp;
    i = v.length;
    while (i) {
      j = parseInt(Math.random() * i);
      i -= 1;
      temp = v[i];
      v[i] = v[j];
      v[j] = temp;
    }
    return v;
  };
  countStr = function(list, elt) {
    var count, member, _i, _len;
    count = 0;
    for (_i = 0, _len = list.length; _i < _len; _i++) {
      member = list[_i];
      if (member.toString() === elt.toString()) {
        count++;
      }
    }
    return count;
  };
  numericSort = function(array) {
    return array.sort(function(a, b) {
      return a - b;
    });
  };
  this.State = State;
  this.PlayerState = PlayerState;
}).call(this);
