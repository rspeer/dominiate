from dominionstats.utils import get_mongo_connection
from dominionstats.game import Game, PlayerDeck
import card_info
from collections import defaultdict
import math
import json
import sys
import numpy as np
from pymongo import ASCENDING, DESCENDING
from csc.util.ordered_set import OrderedSet

con = get_mongo_connection()
DB = con.test

MAX_TURNS = 40
REQUIRED_PLAYERS = 2

CARDS = sorted(card_info._card_info_rows.keys())
CARDSET = OrderedSet()
for card1 in CARDS:
    CARDSET.add(card1)
NCARDS = len(CARDS)

def vp_only(deck):
    newdeck = {}
    for card in deck:
        if card_info.IsVictory(card) or card == u'Curse':
            newdeck[card] = deck[card]
    return newdeck

def count_vp(deck):
    vp = 0
    for card, count in deck.items():
        vp += card_info.VPPerCard(card) * count
    return vp

def decks_by_turn(game):
    turn_ordered_players = sorted(game.PlayerDecks(),
                                  key=PlayerDeck.TurnOrder)
    nplayers = len(turn_ordered_players)
    turn_num = 1
    player_num = 0
    for state in game.GameStateIterator():
        player = turn_ordered_players[player_num].player_name
        balanced_points = turn_ordered_players[player_num].WinPoints() - 1
        deck = dict(state.player_decks[player])
        yield (turn_num, deck, balanced_points)

        player_num += 1
        if (player_num == nplayers):
            player_num = 0
            turn_num += 1
        if turn_num > MAX_TURNS:
            break

    while turn_num <= MAX_TURNS:
        player = turn_ordered_players[player_num].player_name
        balanced_points = turn_ordered_players[player_num].WinPoints() - 1
        deck = dict(turn_ordered_players[player_num].Deck())
        yield (turn_num, deck, balanced_points)

        player_num += 1
        if (player_num == nplayers):
            player_num = 0
            turn_num += 1


def deck_to_features(deck):
    my_cards = {}
    my_unique = {}
    decktot = 0
    n_actions = 0
    
    for card, count in deck.items():
        decktot += count
        if card_info.IsAction(card):
            n_actions += 1

    my_cards['vp'] = count_vp(deck)/10.0
    my_cards['n'] = decktot/10.0
    my_cards['actions'] = n_actions/5.0
    if decktot < 5:
        decktot = 5
    for card, count in deck.items():
        my_cards[card] = count*5.0/decktot
        my_unique[card] = 1

    my_cards['unique'] = len(my_unique)/5.0
    return my_cards, my_unique

def should_learn(game):
    return (len(game.player_decks) == REQUIRED_PLAYERS and
            game.player_decks[0].win_points != 1.0)

def games_to_vowpal(games):
    out = [open('static/output/vowpal/turn%02d.txt' % turn, 'w')
           for turn in xrange(3, 25)]
    counter = 0
    for gamedata in games:
        game = Game(gamedata)
        if should_learn(game):
            counter += 1
            if counter % 1000 == 0:
                print counter
                for file in out:
                    file.flush()
            turn_data = defaultdict(dict)
            turn_count = defaultdict(int)
            for turn_num, deck_state, points in decks_by_turn(game):
                if points > 0:
                    turn_data[turn_num]['winner'] = deck_state
                elif points < 0:
                    turn_data[turn_num]['loser'] = deck_state
                turn_count[turn_num] += 1
            for turn_num in xrange(3, 25):
                data = turn_data[turn_num]
                if (turn_count[turn_num] == REQUIRED_PLAYERS
                and 'winner' in data and 'loser' in data):
                    print >> out[turn_num-3],\
                    data_to_vowpal(data['winner'], data['loser'], 1, game.id)

                    print >> out[turn_num-3],\
                    data_to_vowpal(data['loser'], data['winner'], -1, game.id)
    for file in out:
        file.close()

def dict_to_vowpal(dict):
    parts = ['%s:%4.4f' % (name.replace(' ', '_'), count)
             for name, count in dict.items()]
    return ' '.join(parts)

def data_to_vowpal(mydeck, oppdeck, win, tag=''):
    """
    example:
    1 1.0 id_320ab93f|Cards Copper:-0.3 Smithy:0.1 ...
    """
    mycards, myunique = deck_to_features(mydeck)
    oppcards, oppunique = deck_to_features(oppdeck)
    result = '%d 1 %s|cards %s |opponent %s |unique %s |vsunique %s' %\
      (win, tag, dict_to_vowpal(mycards), dict_to_vowpal(oppcards),
       dict_to_vowpal(myunique), dict_to_vowpal(oppunique))
    return result

def write_test_file():
    outfile = open('static/output/vowpal/test2cards.txt', 'w')
    oppdict = {'Copper': 7, 'Estate': 3}
    for card1 in CARDS:
        for card2 in CARDS:
            if card2 >= card1:
                testdict = defaultdict(float)
                testdict['Copper'] = 7
                testdict['Estate'] = 3
                testdict[card1] += 1
                testdict[card2] += 1
                name = (card1+'+'+card2).replace(' ', '_')
                print >> outfile, data_to_vowpal(testdict, oppdict, 0, name)
    outfile.close()

def write_single_test():
    outfile = open('static/output/vowpal/test1card.txt', 'w')
    oppdict = {'Copper': 7, 'Estate': 3}
    for card1 in CARDS:
        testdict = defaultdict(float)
        testdict['Copper'] = 7
        testdict['Estate'] = 3
        testdict[card1] += 1
        name = card1.replace(' ', '_')
        print >> outfile, data_to_vowpal(testdict, oppdict, 0, name)
    outfile.close()

if __name__ == '__main__':
    games_to_vowpal(DB.games.find())
