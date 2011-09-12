(function() {
  var BasicAI, PlayerState, State, action, applyBenefit, basicCard, c, compileStrategies, count, countStr, duration, makeCard, makeStrategy, noColony, numericSort, playGame, playStep, shuffle, stringify, transferCard, transferCardToTop;
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  compileStrategies = function(scripts, errorCallbacks) {
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
        errorCallbacks[i](e);
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
    window.tracker.setPlayers((function() {
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
    return window.setZeroTimeout(function() {
      return playStep(state, ret);
    });
  };
  playStep = function(state, ret) {
    if (state.gameIsOver()) {
      return ret(state);
    } else {
      state.doPlay();
      return window.setZeroTimeout(function() {
        return playStep(state, ret);
      });
    }
  };
  this.compileStrategies = compileStrategies;
  this.playGame = playGame;
  count = function(list, elt) {
    var member, _i, _len;
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
  BasicAI = (function() {
    function BasicAI() {}
    BasicAI.prototype.name = 'BasicAI';
    BasicAI.prototype.choosePriority = function(state, choices, priorityfunc) {
      var bestChoice, bestIndex, choice, index, priority, _i, _len, _ref;
      priority = priorityfunc(state);
      bestChoice = null;
      bestIndex = null;
      for (_i = 0, _len = choices.length; _i < _len; _i++) {
        choice = choices[_i];
        index = priority.indexOf(stringify(choice));
        if (index !== -1 && (bestIndex === null || index < bestIndex)) {
          bestIndex = index;
          bestChoice = choice;
        }
      }
      if (bestChoice === null && __indexOf.call(choices, null) < 0) {
        return (_ref = choices[0]) != null ? _ref : null;
      }
      return bestChoice;
    };
    BasicAI.prototype.chooseValue = function(state, choices, valuefunc) {
      var bestChoice, bestValue, choice, value, _i, _len, _ref;
      bestChoice = null;
      bestValue = -Infinity;
      for (_i = 0, _len = choices.length; _i < _len; _i++) {
        choice = choices[_i];
        if (choice === null) {
          value = 0;
        } else {
          value = valuefunc(state, choice);
        }
        if (value > bestValue) {
          bestValue = value;
          bestChoice = choice;
        }
      }
      if (bestChoice === null && __indexOf.call(choices, null) < 0) {
        return (_ref = choices[0]) != null ? _ref : null;
      }
      return bestChoice;
    };
    BasicAI.prototype.chooseAction = function(state, choices) {
      if (this.actionValue != null) {
        return this.chooseValue(state, choices, this.actionValue);
      } else {
        return this.choosePriority(state, choices, this.actionPriority);
      }
    };
    BasicAI.prototype.chooseTreasure = function(state, choices) {
      if (this.treasureValue != null) {
        return this.chooseValue(state, choices, this.treasureValue);
      } else {
        return this.choosePriority(state, choices, this.treasurePriority);
      }
    };
    BasicAI.prototype.chooseGain = function(state, choices) {
      if (this.gainValue != null) {
        return this.chooseValue(state, choices, this.gainValue);
      } else {
        return this.choosePriority(state, choices, this.gainPriority);
      }
    };
    BasicAI.prototype.chooseDiscard = function(state, choices) {
      if (this.discardValue != null) {
        return this.chooseValue(state, choices, this.discardValue);
      } else {
        return this.choosePriority(state, choices, this.discardPriority);
      }
    };
    BasicAI.prototype.chooseTrash = function(state, choices) {
      if (this.trashValue != null) {
        return this.chooseValue(state, choices, this.trashValue);
      } else {
        return this.choosePriority(state, choices, this.trashPriority);
      }
    };
    BasicAI.prototype.gainPriority = function(state) {
      var _ref, _ref2;
      return [state.current.countInDeck("Platinum") > 0 ? "Colony" : void 0, state.countInSupply("Colony") <= 6 ? "Province" : void 0, (0 < (_ref = state.gainsToEndGame()) && _ref <= 5) ? "Duchy" : void 0, (0 < (_ref2 = state.gainsToEndGame()) && _ref2 <= 2) ? "Estate" : void 0, "Platinum", "Gold", "Silver", state.gainsToEndGame() <= 3 ? "Copper" : void 0, null];
    };
    BasicAI.prototype.actionPriority = function(state) {
      return [state.current.menagerieDraws() === 3 ? "Menagerie" : void 0, state.current.shantyTownDraws(true) === 2 ? "Shanty Town" : void 0, "Trusty Steed", "Festival", "University", "Bazaar", "Worker's Village", "City", "Village", "Bag of Gold", "Grand Market", "Alchemist", "Laboratory", "Caravan", "Fishing Village", "Market", "Peddler", "Great Hall", state.current.actions > 1 ? "Smithy" : void 0, state.current.inPlay.length >= 2 ? "Conspirator" : void 0, "Pawn", "Warehouse", "Menagerie", "Tournament", "Cellar", state.current.actions === 1 ? "Shanty Town" : void 0, "Nobles", "Followers", "Mountebank", "Witch", "Goons", "Wharf", "Militia", "Princess", "Steward", "Bridge", "Horse Traders", state.current.countInHand("Copper") >= 3 ? "Coppersmith" : void 0, "Smithy", "Council Room", "Merchant Ship", state.current.countInHand("Estate") >= 1 ? "Baron" : void 0, "Monument", "Adventurer", "Harvest", "Woodcutter", state.current.countInHand("Copper") >= 2 ? "Coppersmith" : void 0, "Conspirator", "Moat", "Chapel", "Workshop", "Coppersmith", "Shanty Town", null];
    };
    BasicAI.prototype.treasurePriority = function(state) {
      return ["Platinum", "Diadem", "Philosopher's Stone", "Gold", "Harem", "Silver", "Quarry", "Copper", "Potion", "Bank"];
    };
    BasicAI.prototype.discardPriority = function(state) {
      return ["Colony", "Province", "Duchy", "Curse", "Estate", "Copper", null, "Silver"];
    };
    BasicAI.prototype.trashPriority = function(state) {
      return ["Curse", state.gainsToEndGame() > 4 ? "Estate" : void 0, state.current.getTotalMoney() > 4 ? "Copper" : void 0, state.current.turnsTaken >= 10 ? "Potion" : void 0, state.gainsToEndGame() > 2 ? "Estate" : void 0, null, "Copper", "Potion", "Estate", "Silver"];
    };
    BasicAI.prototype.chooseBaronDiscard = function(state) {
      return true;
    };
    BasicAI.prototype.chooseBenefit = function(state, choices) {
      var actionBalance, actionValue, best, bestValue, buyValue, card, cardValue, choice, coinValue, trashValue, trashableCards, trashes, usableActions, value, _i, _j, _len, _len2, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
      buyValue = 1;
      cardValue = 2;
      coinValue = 3;
      trashValue = 4;
      actionValue = 10;
      trashableCards = 0;
      actionBalance = state.current.actionBalance();
      usableActions = Math.max(0, -actionBalance);
      if (actionBalance >= 1) {
        cardValue += actionBalance;
      }
      _ref = state.current.hand;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        if (this.chooseTrash(state, [card, null]) === card) {
          trashableCards += 1;
        }
      }
      best = null;
      bestValue = -1000;
      for (_j = 0, _len2 = choices.length; _j < _len2; _j++) {
        choice = choices[_j];
        value = cardValue * ((_ref2 = choice.cards) != null ? _ref2 : 0);
        value += coinValue * ((_ref3 = choice.coins) != null ? _ref3 : 0);
        value += buyValue * ((_ref4 = choice.buys) != null ? _ref4 : 0);
        trashes = (_ref5 = choice.trashes) != null ? _ref5 : 0;
        if (trashes <= trashableCards) {
          value += trashValue * trashes;
        } else {
          value -= trashValue * trashes;
        }
        value += actionValue * Math.min((_ref6 = choice.actions) != null ? _ref6 : 0, usableActions);
        if (value > bestValue) {
          best = choice;
          bestValue = value;
        }
      }
      return best;
    };
    BasicAI.prototype.toString = function() {
      return this.name;
    };
    return BasicAI;
  })();
  this.BasicAI = BasicAI;
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
    playEffect: function(state) {},
    gainInPlayEffect: function(state) {},
    cleanupEffect: function(state) {},
    durationEffect: function(state) {},
    shuffleEffect: function(state) {},
    attackReaction: function(state) {},
    gainReaction: function(state) {},
    onPlay: function(state) {
      var cardsToDraw;
      state.current.actions += this.getActions(state);
      state.current.coins += this.getCoins(state);
      state.current.potions += this.getPotion(state);
      state.current.buys += this.getBuys(state);
      cardsToDraw = this.getCards(state);
      if (cardsToDraw > 0) {
        state.drawCards(state.current, cardsToDraw);
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
    reactToAttack: function(player) {
      return this.attackReaction(player);
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
        default:
          return 40;
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
        case 3:
        case 4:
          return 12;
        default:
          return 15;
      }
    }
  });
  makeCard('Duchy', c.Estate, {
    cost: 5,
    vp: 3
  });
  makeCard('Province', c.Estate, {
    cost: 8,
    vp: 6
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
      return 30;
    }
  });
  makeCard('Copper', c.Silver, {
    cost: 0,
    coins: 1,
    getCoins: function(state) {
      var _ref;
      return (_ref = state.copperValue) != null ? _ref : 1;
    }
  });
  makeCard('Gold', c.Silver, {
    cost: 6,
    coins: 3
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
    playEffect: function(state) {
      return state.current.potions += 1;
    },
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
  makeCard('Great Hall', action, {
    cost: 3,
    actions: 1,
    cards: 1,
    vp: 1,
    isVictory: true
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
  makeCard('Harem', c.Silver, {
    cost: 6,
    isVictory: true,
    vp: 2
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
  makeCard('Caravan', duration, {
    cost: 4,
    cards: +1,
    actions: +1,
    durationCards: +1
  });
  makeCard('Fishing Village', duration, {
    cost: 3,
    cards: 0,
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
    cards: 0,
    coins: +2,
    durationCards: 0,
    durationCoins: +2
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
  makeCard('Bag of Gold', action, {
    cost: 0,
    actions: +1,
    isPrize: true,
    mayBeBought: function(state) {
      return false;
    },
    playEffect: function(state) {
      state.current.gainCard(c.Gold);
      state.log("...putting the Gold on top of the deck.");
      return transferCardToTop(c.Gold, state.current.discard, state.current.draw);
    }
  });
  makeCard('Bank', c.Silver, {
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
    }
  });
  makeCard('Baron', action, {
    cost: 4,
    buys: 1,
    playEffect: function(state) {
      var discardEstate, _ref;
      discardEstate = false;
      if (_ref = c.Estate, __indexOf.call(state.current.hand, _ref) >= 0) {
        discardEstate = state.current.ai.chooseBaronDiscard(state);
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
  /*
  # not defining this yet; involves implementing a possibly-important but
  # very boring decision
  makeCard 'Bureaucrat', action, {
    cost: 4
    isAttack: true
    playEffect: (state) ->
      state.attackOpponents (opp) ->
        
  }
  */
  makeCard('Cellar', action, {
    cost: 2,
    actions: 1,
    playEffect: function(state) {
      var numDiscarded, startingCards;
      startingCards = state.current.hand.length;
      state.allowDiscard(state.current, 1000);
      numDiscarded = startingCards - state.current.hand.length;
      return state.drawCards(state.current, numDiscarded);
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
  makeCard('Diadem', c.Silver, {
    cost: 0,
    isPrize: true,
    mayBeBought: function(state) {
      return false;
    },
    getCoins: function(state) {
      return 2 + state.current.actions;
    }
  });
  makeCard("Duke", c.Estate, {
    cost: 5,
    getVP: function(state) {
      var card, vp, _i, _len, _ref;
      vp = 0;
      _ref = state.current.getDeck();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        if (card === c.Duchy) {
          vp += 1;
        }
      }
      return vp;
    }
  });
  makeCard("Followers", action, {
    cost: 0,
    isAttack: true,
    isPrize: true,
    mayBeBought: function(state) {
      return false;
    },
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
  makeCard("Gardens", c.Estate, {
    cost: 4,
    getVP: function(state) {
      return Math.floor(state.current.getDeck().length / 10);
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
  makeCard("Horse Traders", action, {
    cost: 4,
    buys: 1,
    coins: 3,
    isReaction: true,
    playEffect: function(state) {
      return state.requireDiscard(state.current, 2);
    },
    durationEffect: function(state) {
      transferCard(c['Horse Traders'], state.current.duration, state.current.hand);
      return state.drawCards(state.current, 1);
    },
    attackReaction: function(player) {
      return transferCard(c['Horse Traders'], player.hand, player.duration);
    }
  });
  makeCard("Menagerie", action, {
    cost: 3,
    actions: 1,
    playEffect: function(state) {
      state.revealHand(state.current);
      return state.drawCards(state.current, state.current.menagerieDraws());
    }
  });
  makeCard("Militia", action, {
    cost: 4,
    coins: 2,
    isAttack: true,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        if (opp.hand.length > 3) {
          return state.requireDiscard(opp, opp.hand.length - 3);
        }
      });
    }
  });
  makeCard("Mountebank", action, {
    cost: 5,
    coins: 2,
    isAttack: true,
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
  makeCard("Goons", c.Militia, {
    cost: 6,
    coins: 2,
    buys: 1
  });
  makeCard("Moat", action, {
    cost: 2,
    cards: +2,
    isReaction: true,
    attackReaction: function(player) {
      return player.moatProtected = true;
    }
  });
  makeCard("Monument", action, {
    cost: 4,
    coins: 2,
    playEffect: function(state) {
      return state.current.chips += 1;
    }
  });
  makeCard('Nobles', action, {
    cost: 6,
    isVictory: true,
    vp: 2,
    playEffect: function(state) {
      var benefit;
      benefit = state.current.ai.chooseBenefit(state, [
        {
          actions: 2
        }, {
          cards: 3
        }
      ]);
      return applyBenefit(state, benefit);
    }
  });
  makeCard('Pawn', action, {
    cost: 2,
    playEffect: function(state) {
      var benefit;
      benefit = state.current.ai.chooseBenefit(state, [
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
  makeCard("Philosopher's Stone", c.Silver, {
    cost: 3,
    costPotion: 1,
    getCoins: function(state) {
      return Math.floor((state.current.draw.length + state.current.discard.length) / 5);
    }
  });
  makeCard('Princess', action, {
    cost: 0,
    buys: 1,
    isPrize: true,
    mayBeBought: function(state) {
      return false;
    },
    playEffect: function(state) {
      return state.bridges += 2;
    }
  });
  makeCard('Quarry', c.Silver, {
    cost: 4,
    coins: 1,
    playEffect: function(state) {
      return state.quarries += 1;
    }
  });
  makeCard('Shanty Town', action, {
    cost: 3,
    actions: +2,
    playEffect: function(state) {
      state.revealHand(0);
      return state.drawCards(state.current, state.current.shantyTownDraws());
    }
  });
  makeCard('Steward', action, {
    cost: 3,
    playEffect: function(state) {
      var benefit;
      benefit = state.current.ai.chooseBenefit(state, [
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
      var choice, choices, opp, opposingProvince, _i, _len, _ref, _ref2, _ref3;
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
        state.log("" + state.current.ai + " reveals a Province.");
        choices = state.prizes;
        if (state.supply[c.Duchy] > 0) {
          choices.push(c.Duchy);
        }
        choice = state.gainOneOf(state.current, choices);
        if (choice !== null) {
          state.log("...putting the " + choice + " on top of the deck.");
          transferCardToTop(choice, state.current.discard, state.current.draw);
        }
      }
      if (!opposingProvince) {
        state.current.coins += 1;
        return state.current.drawCards(1);
      }
    }
  });
  makeCard("Trusty Steed", c["Bag of Gold"], {
    actions: 0,
    playEffect: function(state) {
      var benefit;
      benefit = state.current.ai.chooseBenefit(state, [
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
  makeCard('Warehouse', action, {
    cost: 3,
    playEffect: function(state) {
      state.drawCards(state.current, 3);
      return state.requireDiscard(state.current, 3);
    }
  });
  makeCard('Witch', action, {
    cost: 5,
    cards: 2,
    playEffect: function(state) {
      return state.attackOpponents(function(opp) {
        return state.gainCard(opp, c.Curse);
      });
    }
  });
  makeCard('Workshop', action, {
    cost: 4,
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
  if (typeof exports !== "undefined" && exports !== null) {
    c = require('./cards').c;
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
      this.chips = 0;
      this.hand = [];
      this.discard = [c.Copper, c.Copper, c.Copper, c.Copper, c.Copper, c.Copper, c.Copper, c.Estate, c.Estate, c.Estate];
      this.draw = [];
      this.inPlay = [];
      this.duration = [];
      this.setAside = [];
      this.moatProtected = false;
      this.turnsTaken = 0;
      this.ai = ai;
      this.logFunc = logFunc;
      this.drawCards(5);
      return this;
    };
    PlayerState.prototype.getDeck = function() {
      return this.draw.concat(this.discard.concat(this.hand.concat(this.inPlay.concat(this.duration.concat(this.mats.nativeVillage.concat(this.mats.island))))));
    };
    PlayerState.prototype.countInDeck = function(card) {
      var card2, _i, _len, _ref;
      count = 0;
      _ref = this.getDeck();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card2 = _ref[_i];
        if (card.toString() === card2.toString()) {
          count++;
        }
      }
      return count;
    };
    PlayerState.prototype.numCardsInDeck = function() {
      return this.getDeck().length;
    };
    PlayerState.prototype.getVP = function(state) {
      var card, total, _i, _len, _ref;
      total = 0;
      _ref = this.getDeck();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        total += card.getVP(state);
      }
      return total;
    };
    PlayerState.prototype.getTotalMoney = function() {
      var card, total, _i, _len, _ref;
      total = 0;
      _ref = this.getDeck();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        total += card.coins;
      }
      return total;
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
      var card, _i, _len, _ref;
      count = 0;
      _ref = this.getDeck();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
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
      var card, cardsToDraw, seen, _i, _len, _ref;
      seen = {};
      cardsToDraw = 3;
      _ref = this.hand;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
        if (seen[card.name] != null) {
          cardsToDraw = 1;
          break;
        }
        seen[card.name] = true;
      }
      return cardsToDraw;
    };
    PlayerState.prototype.shantyTownDraws = function(hypothetical) {
      var card, cardsToDraw, skippedShanty, _i, _len, _ref;
      if (hypothetical == null) {
        hypothetical = false;
      }
      cardsToDraw = 2;
      skippedShanty = false;
      _ref = this.hand;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
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
      var balance, card, _i, _len, _ref;
      balance = this.actions;
      _ref = this.hand;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        card = _ref[_i];
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
      return this.hand.remove(card);
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
      other.mats = this.mats;
      other.chips = this.chips;
      other.hand = this.hand.slice(0);
      other.draw = this.draw.slice(0);
      other.discard = this.discard.slice(0);
      other.inPlay = this.inPlay.slice(0);
      other.duration = this.duration.slice(0);
      other.setAside = this.setAside.slice(0);
      other.moatProtected = this.moatProtected;
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
      this.bridges = 0;
      this.quarries = 0;
      this.copperValue = 1;
      this.phase = 'start';
      return this;
    };
    State.prototype.makeSupply = function(tableau) {
      var allCards, card, supply, _i, _len, _ref;
      allCards = this.basicSupply.concat(tableau);
      supply = {};
      for (_i = 0, _len = allCards.length; _i < _len; _i++) {
        card = allCards[_i];
        card = (_ref = c[card]) != null ? _ref : card;
        supply[card] = card.startingSupply(this);
      }
      return supply;
    };
    State.prototype.emptyPiles = function() {
      var key, piles, value, _ref;
      piles = [];
      _ref = this.supply;
      for (key in _ref) {
        value = _ref[key];
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
      var emptyPiles, playerName, turns, vp, _i, _len, _ref, _ref2;
      if (this.phase !== 'start') {
        return false;
      }
      emptyPiles = this.emptyPiles();
      if (emptyPiles.length >= this.totalPilesToEndGame() || (this.nPlayers < 5 && emptyPiles.length >= 3) || __indexOf.call(emptyPiles, 'Province') >= 0 || __indexOf.call(emptyPiles, 'Colony') >= 0) {
        this.log("Empty piles: " + emptyPiles);
        _ref = this.getFinalStatus();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          _ref2 = _ref[_i], playerName = _ref2[0], vp = _ref2[1], turns = _ref2[2];
          this.log("" + playerName + " took " + turns + " turns and scored " + vp + " points.");
        }
        return true;
      }
      return false;
    };
    State.prototype.getFinalStatus = function() {
      var player, _i, _len, _ref, _results;
      _ref = this.players;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        player = _ref[_i];
        _results.push([player.ai.toString(), player.getVP(this), player.turnsTaken]);
      }
      return _results;
    };
    State.prototype.getWinners = function() {
      var best, bestScore, modScore, player, score, scores, turns, _i, _len, _ref;
      scores = this.getFinalStatus();
      best = [];
      bestScore = -Infinity;
      for (_i = 0, _len = scores.length; _i < _len; _i++) {
        _ref = scores[_i], player = _ref[0], score = _ref[1], turns = _ref[2];
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
      var _ref;
      return (_ref = this.supply[card]) != null ? _ref : 0;
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
      var card, count, counts, minimum, piles, _i, _len, _ref;
      counts = (function() {
        var _ref, _results;
        _ref = this.supply;
        _results = [];
        for (card in _ref) {
          count = _ref[card];
          _results.push(count);
        }
        return _results;
      }).call(this);
      numericSort(counts);
      piles = this.totalPilesToEndGame();
      minimum = 0;
      _ref = counts.slice(0, piles);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        count = _ref[_i];
        minimum += count;
      }
      minimum = Math.min(minimum, this.supply['Province']);
      if (this.supply['Colony'] != null) {
        minimum = Math.min(minimum, this.supply['Colony']);
      }
      return minimum;
    };
    State.prototype.doPlay = function() {
      switch (this.phase) {
        case 'start':
          this.current.turnsTaken += 1;
          this.log("\n== " + this.current.ai + "'s turn " + this.current.turnsTaken + " ==");
          this.doDurationPhase();
          return this.phase = 'action';
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
          return this.rotatePlayer();
      }
    };
    State.prototype.doDurationPhase = function() {
      var card, i, _ref, _results;
      _results = [];
      for (i = _ref = this.current.duration.length - 1; _ref <= -1 ? i < -1 : i > -1; _ref <= -1 ? i++ : i--) {
        card = this.current.duration[i];
        this.log("" + this.current.ai + " resolves the duration effect of " + card + ".");
        _results.push(card.onDuration(this));
      }
      return _results;
    };
    State.prototype.doActionPhase = function() {
      var card, validActions, _i, _len, _ref, _results;
      _results = [];
      while (this.current.actions > 0) {
        validActions = [null];
        _ref = this.current.hand;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          card = _ref[_i];
          if (card.isAction && __indexOf.call(validActions, card) < 0) {
            validActions.push(card);
          }
        }
        action = this.current.ai.chooseAction(this, validActions);
        if (action === null) {
          return;
        }
        this.log("" + this.current.ai + " plays " + action + ".");
        if (__indexOf.call(this.current.hand, action) < 0) {
          this.warn("" + this.current.ai + " chose an invalid action.");
          return;
        }
        this.current.hand.remove(action);
        this.current.inPlay.push(action);
        this.current.actions -= 1;
        _results.push(action.onPlay(this));
      }
      return _results;
    };
    State.prototype.doTreasurePhase = function() {
      var card, idx, treasure, validTreasures, _i, _len, _ref, _results;
      _results = [];
      while (true) {
        validTreasures = [null];
        _ref = this.current.hand;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          card = _ref[_i];
          if (card.isTreasure && __indexOf.call(validTreasures, card) < 0) {
            validTreasures.push(card);
          }
        }
        treasure = this.current.ai.chooseTreasure(this, validTreasures);
        if (treasure === null) {
          return;
        }
        this.log("" + this.current.ai + " plays " + treasure + ".");
        idx = this.current.hand.indexOf(treasure);
        if (__indexOf.call(this.current.hand, treasure) < 0) {
          this.warn("" + this.current.ai + " chose an invalid treasure");
          return;
        }
        this.current.hand.remove(treasure);
        this.current.inPlay.push(treasure);
        _results.push(treasure.onPlay(this));
      }
      return _results;
    };
    State.prototype.doBuyPhase = function() {
      var buyable, card, cardname, choice, coinCost, count, goonses, potionCost, _ref, _ref2, _ref3, _results;
      _results = [];
      while (this.current.buys > 0) {
        buyable = [null];
        _ref = this.supply;
        for (cardname in _ref) {
          count = _ref[cardname];
          card = c[cardname];
          if (card.mayBeBought(this) && count > 0) {
            _ref2 = card.getCost(this), coinCost = _ref2[0], potionCost = _ref2[1];
            if (coinCost <= this.current.coins && potionCost <= this.current.potions) {
              buyable.push(card);
            }
          }
        }
        this.log("Coins: " + this.current.coins + ", Potions: " + this.current.potions + ", Buys: " + this.current.buys);
        choice = this.current.ai.chooseGain(this, buyable);
        if (choice === null) {
          return;
        }
        this.log("" + this.current.ai + " buys " + choice + ".");
        _ref3 = choice.getCost(this), coinCost = _ref3[0], potionCost = _ref3[1];
        this.current.coins -= coinCost;
        this.current.potions -= potionCost;
        this.current.buys -= 1;
        this.gainCard(this.current, choice, true);
        choice.onBuy(this);
        goonses = this.current.countInPlay('Goons');
        _results.push(goonses > 0 ? (this.log("...gaining " + goonses + " VP."), this.current.chips += goonses) : void 0);
      }
      return _results;
    };
    State.prototype.doCleanupPhase = function() {
      var card;
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
      this.copperValue = 1;
      this.bridges = 0;
      this.quarries = 0;
      return this.current.drawCards(5);
    };
    State.prototype.rotatePlayer = function() {
      this.players = this.players.slice(1, this.nPlayers).concat([this.players[0]]);
      this.current = this.players[0];
      return this.phase = 'start';
    };
    State.prototype.gainCard = function(player, card, suppressMessage) {
      if (suppressMessage == null) {
        suppressMessage = false;
      }
      if (__indexOf.call(this.prizes, card) >= 0 || this.supply[card] > 0) {
        if (!suppressMessage) {
          this.log("" + player.ai + " gains " + card + ".");
        }
        player.discard.push(card);
        if (__indexOf.call(this.prizes, card) >= 0) {
          return this.prizes.remove(card);
        } else {
          return this.supply[card] -= 1;
        }
      } else {
        return this.log("There is no " + card + " to gain.");
      }
    };
    State.prototype.revealHand = function(player) {};
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
      var choice, numDiscarded, validDiscards, _results;
      numDiscarded = 0;
      _results = [];
      while (numDiscarded < num) {
        validDiscards = player.hand.slice(0);
        validDiscards.push(null);
        choice = player.ai.chooseDiscard(this, validDiscards);
        if (choice === null) {
          return;
        }
        numDiscarded++;
        _results.push(player.doDiscard(choice));
      }
      return _results;
    };
    State.prototype.requireDiscard = function(player, num) {
      var choice, numDiscarded, validDiscards, _results;
      numDiscarded = 0;
      _results = [];
      while (numDiscarded < num) {
        validDiscards = player.hand.slice(0);
        if (validDiscards.length === 0) {
          return;
        }
        choice = player.ai.chooseDiscard(this, validDiscards);
        numDiscarded++;
        _results.push(player.doDiscard(choice));
      }
      return _results;
    };
    State.prototype.allowTrash = function(player, num) {
      var choice, numTrashed, valid, _results;
      numTrashed = 0;
      _results = [];
      while (numTrashed < num) {
        valid = player.hand.slice(0);
        valid.push(null);
        choice = player.ai.chooseTrash(this, valid);
        if (choice === null) {
          return;
        }
        this.log("" + player.ai + " trashes " + choice + ".");
        numTrashed++;
        _results.push(player.doTrash(choice));
      }
      return _results;
    };
    State.prototype.requireTrash = function(player, num) {
      var choice, numTrashed, valid, _results;
      numTrashed = 0;
      _results = [];
      while (numTrashed < num) {
        valid = player.hand.slice(0);
        if (valid.length === 0) {
          return;
        }
        choice = player.ai.chooseTrash(this, valid);
        this.log("" + player.ai + " trashes " + choice + ".");
        numTrashed++;
        _results.push(player.doTrash(choice));
      }
      return _results;
    };
    State.prototype.gainOneOf = function(player, options) {
      var choice;
      choice = player.ai.chooseGain(this, options);
      if (choice === null) {
        return null;
      }
      this.gainCard(player, choice);
      return choice;
    };
    State.prototype.attackOpponents = function(effect) {
      var opp, _i, _len, _ref, _results;
      _ref = this.players.slice(1);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        opp = _ref[_i];
        _results.push(this.attackPlayer(opp, effect));
      }
      return _results;
    };
    State.prototype.attackPlayer = function(player, effect) {
      var card, i, _ref, _ref2;
      player.moatProtected = false;
      for (i = _ref = player.hand.length - 1; _ref <= -1 ? i < -1 : i > -1; _ref <= -1 ? i++ : i--) {
        card = player.hand[i];
        if (card.isReaction) {
          card.reactToAttack(player);
        }
      }
      if (player.moatProtected) {
        return this.log("" + player.ai + " is protected by a Moat.");
      } else if (_ref2 = c.Lighthouse, __indexOf.call(player.duration, _ref2) >= 0) {
        return this.log("" + player.ai + " is protected by the Lighthouse.");
      } else {
        return effect(player);
      }
    };
    State.prototype.copy = function() {
      var key, newPlayers, newState, newSupply, player, value, _i, _len, _ref, _ref2;
      newSupply = {};
      _ref = this.supply;
      for (key in _ref) {
        value = _ref[key];
        newSupply[key] = value;
      }
      newPlayers = [];
      _ref2 = this.players;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        player = _ref2[_i];
        newPlayers.push(player.copy());
      }
      newState = new State();
      newState.players = newPlayers;
      newState.current = newPlayers[0];
      newState.nPlayers = this.nPlayers;
      newState.bridges = this.bridges;
      newState.quarries = this.quarries;
      newState.copperValue = this.copperValue;
      newState.phase = this.phase;
      newState.logFunc = this.logFunc;
      return newState;
    };
    State.prototype.log = function(obj) {
      if (this.logFunc != null) {
        return this.logFunc(obj);
      } else {
        if (typeof console !== "undefined" && console !== null) {
          return console.log(obj);
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
    var member, _i, _len;
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
