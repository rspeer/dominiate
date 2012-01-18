# These heuristics are intended to estimate the average effect on your hand
# state when you play the card, not to define what the card actually does.
#
# NOTE: This is not used anywhere yet. I thought it would be useful as a base
# case for code that analyzes a game tree.
#
# The values are all constants, even when the card's effect isn't, so that in
# the base case a hand can be quickly evaluated. The more sophisticated way to
# evaluate a hand, of course, is to consider the actual effect of playing the
# card, and evaluate the resulting hand, recursively. As such, it doesn't even
# matter when these values are wrong for complex actions, as long as they're
# not incredibly wrong.
#
# The +'s have no effect on the values, they just make some of them sound more
# natural.
#
# Victory cards are modeled as cards that replace their action and do nothing
# (this isn't accurate, but the things that would care about the difference --
# like Libraries -- aren't accurate either.)
#
# If they appeared as the default -1 action, it would imply that there was some
# benefit to having +actions with victory cards.
#
# "Churn" is how many more cards you get to see than you get to keep. (Think of
# what Cellar and Warehouse do, even though they're different.) This doesn't
# model the effect of cycling through your deck or stacking it; that's too hard
# to describe without describing what the card actually does in a situation.

heuristics = {
  default: {
    actions: -1   # _difference_ in number of actions
    attack: 0     # how much it hurts your opponents (negative means it helps)
    nextTurn: 0   # estimated benefit of a duration or top-decker
    buys: 0       # number of +buys
    cards: -1     # _difference_ in cards in hand
    coins: 0      # number of coins you get
    gain: 0       # number of (good) cards you gain
    trash: 0      # number of cards you can trash
    chips: 0      # number of VP chips
  }
  Adventurer: {
    actions: -1
    cards: +1
  }
  Alchemist: {
    actions: 0
    cards: +1
    nextTurn: +1
  }
  Ambassador: {
    trash: 1.5
    cards: -2.5
    attack: 1
  }
  Apothecary: {
    actions: 0
    cards: +0.5
  }
  Apprentice: {
    actions: 0
    cards: +2
    trash: 1
  }
  "Bag of Gold": {
    actions: 0
    nextTurn: +2
    gain: 1
  }
  Bank: {
    actions: 0
    coins: 4
  }
  Baron: {
    coins: +3
    buys: +1
    gain: 0.1
  }
  Bazaar: {
    actions: +1
    cards: 0
    coins: +1
  }
  Bishop: {
    trash: 1
    cards: -2
    coins: +1
    chips: +2
  }
  "Black Market": {
    coins: +2
    buys: 0.5   # you might use it as a buy
    gain: 0.3   # you might benefit from it
  }
  Bridge: {
    coins: +3
    buys: +1
  }
  Bureaucrat: {
    attack: 0.5
    gain: 0.5
  }
  Caravan: {
    actions: 0
    cards: 0
    nextTurn: +1
  }
  Cellar: {
    actions: 0
    churn: 3
  }
  Chancellor: {
    coins: +2
  }
  Chapel: {
    trash: 4
    cards: -4
  }
  City: {
    actions: +1
    cards: +0.2
    coins: +0.1
    buys: +0.1
  }
  Colony: {actions: 0}
  Conspirator: {
    coins: +1
    actions: -0.6
    cards: -0.6
  }
  Contraband: {
    actions: 0
    coins: +3
    buys: +1
    attack: -1
  }
  Copper: {
    actions: 0
    coins: +1
  }
  Coppersmith: {
    coins: +2
  }
  "Council Room": {
    cards: +3
    buys: +1
    attack: -1
  }
  "Counting House": {
    cards: +3
  }
  Courtyard: {
    cards: +1
    churn: 1
  }
  Curse: {actions: 0}
  Cutpurse: {
    attack: 1
    coins: +2
  }
  Diadem: {
    actions: 0
    coins: +3
  }
  Duchy: {actions: 0}
  Duke: {actions: 0}
  Embargo: {
    coins: +2
  }
  Envoy: {
    cards: +3
  }
  Estate: {actions: 0}
  Expand: {
    trash: 1
    cards: -2
    gain: 1
  }
  Explorer: {
    gain: 1
    cards: 0
  }
  Fairgrounds: {actions: 0}
  Familiar: {
    attack: 2
    cards: 0
    actions: 0
  }
  "Farming Village": {
    actions: +1
    cards: 0
  }
  Feast: {
    gain: 1
  }
  Festival: {
    actions: +1
    coins: +2
    buys: +1
  }
  "Fishing Village": {
    actions: +1
    coins: +1
    nextTurn: +2
  }
  Followers: {
    attack: 4
    cards: +1
  }
  Forge: {
    trash: 3
    cards: -4
    gain: 1
  }
  "Fortune Teller": {
    attack: 0.5
    coins: +2
  }
  Goons: {
    attack: 2.5
    coins: +2
    chips: +2
  }
  "Grand Market": {
    actions: 0
    cards: 0
    coins: +2
    buys: +1
  }
  "Great Hall": {
    actions: 0
    cards: 0
  }
  Hamlet: {
    actions: +0.5
    buys: +0.5
    cards: -1
  }
  Harem: {
    actions: 0
    coins: +2
  }
  Herbalist: {
    buys: +1
    coins: +1
    nextTurn: +0.5
  }
  Hoard: {
    actions: 0
    gain: 0.5
    coins: +2
  }
  "Horn of Plenty": {
    actions: 0
    gain: 1
  }
  "Horse Traders": {
    cards: -3
    coins: +3
    buys: +1
  }
  "Hunting Party": {
    cards: +1
    actions: 0
  }
  Ironworks: {
    gain: 1
    actions: +0.4
    coins: +0.4
    cards: +0.2
  }
  Island: {
    trash: 1
    cards: -2
  }
  Jester: {
    attack: 1
    coins: +2
    gain: 0.5
  }
  "King's Court": {
    actions: +2
  }
  Laboratory: {
    actions: 0
    cards: +1
  }
  Library: {
    cards: +2
  }
  Lighthouse: {
    nextTurn: +1.5
    coins: +1
    actions: 0
  }
  Loan: {
    actions: 0
    cards: -1
    trash: 1
  }
  Lookout: {
    cards: -1
    trash: 1
  }
  Market: {
    actions: 0
    cards: 0
    coins: +1
    buys: +1
  }
  Masquerade: {
    cards: +1
    trash: 1
  }
  Menagerie: {
    actions: 0
    cards: +1
  }
  "Merchant Ship": {
    nextTurn: +2
    coins: +2
  }
  Militia: {
    attack: 2
    coins: +2
  }
  Mine: {
    trash: 1
    cards: -1
    gain: 1
    coins: +1
  }
  "Mining Village": {
    actions: +1
    cards: 0
  }
  Minion: {
    attack: 0.5
    cards: +1.5
    churn: 1.5
    coins: 1
  }
  Mint: {
    gain: 1
  }
  Moat: {
    cards: +1
  }
  Moneylender: {
    trash: 1
    cards: -2
    coins: +2
  }
  Monument: {
    coins: +2
  }
  Mountebank: {
    attack: 2
    coins: +2
  }
  "Native Village": {
    actions: +1
    cards: +0.5
  }
  Navigator: {
    coins: +2
    nextTurn: +0.5
  }
  Nobles: {
    actions: 0
    cards: +0.5
  }
  Outpost: {
    nextTurn: +0.5
  }
  Pawn: {
    actions: -0.5
    cards: -0.5
    coins: +0.5
    buys: +0.5
  }
  "Pearl Diver": {
    actions: 0
    cards: 0
  }
  Peddler: {
    actions: 0
    cards: 0
    coins: +1
  }
  "Philosopher's Stone": {
    actions: 0
    coins: +4
  }
  "Pirate Ship": {
    attack: 0.5
    coins: +3
  }
  Platinum: {
    actions: 0
    coins: +5
  }
  Possession: {
    nextTurn: +5
  }
  Potion: {
    actions: 0
    potions: +1
  }
  Princess: {
    coins: +4
    buys: +1
  }
  Province: {actions: 0}
  Quarry: {
    actions: 0
    coins: +3
  }
  Rabble: {
    attack: 1
    cards: +2
  }
  Remake: {
    trash: 2
    cards: -3
    gain: 2
  }
  Remodel: {
    trash: 1
    cards: -2
    gain: 1
  }
  "Royal Seal": {
    actions: 0
    coins: 2
    nextTurn: +0.5
  }
  Saboteur: {
    attack: 2.5
  }
  Salvager: {
    trash: 1
    cards: -2
    coins: +2
    buys: +1
  }
  Scout: {
    actions: 0
    cards: +0.5
  }
  "Scrying Pool": {
    actions: 0
    cards: +1
    attack: 1
  }
  "Sea Hag": {
    attack: 3
  }
  "Secret Chamber": {
    cards: -3
    coins: +2
  }
  "Shanty Town": {
    actions: +1
    cards: 0
  }
  Silver: {
    actions: 0
    coins: +2
  }
  Smithy: {
    cards: +2
  }
  Smugglers: {
    gain: 1
  }
  Spy: {
    attack: 1
    actions: 0
    cards: 0
    nextTurn: +0.2
  }
  Stash: {
    actions: 0
    coins: +2
  }
  Steward: {
    trash: 1
    cards: -0.5
    coins: +0.5
    cards: -2
  }
  Swindler: {
    attack: 1.5
    coins: +2
  }
  Tactician: {
    cards: -5
    nextTurn: +6
  }
  Talisman: {
    actions: 0
    coins: 1
  }
  Thief: {
    gain: 0.5
  }
  "Throne Room": {
    actions: +1
  }
  Torturer: {
    attack: 2
    cards: +2
  }
  Tournament: {
  }
  "Trade Route": {
    cards: -2
    trash: 1
    coins: +1
    buys: +1
  }
  "Trading Post": {
    trash: 2
    cards: -2
  }
  Transmute: {
    trash: 1
    gain: 1
    cards: -2
  }
  "Treasure Map": {}
  Treasury: {
    actions: 0
    cards: 0
    coins: +1
    nextTurn: +1
  }
  Tribute: {
    actions: 0
    cards: 0
    coins: +1
  }
  "Trusty Steed": {
    actions: +0.7
    cards: +0.7
    coins: +0.6
  }
  University: {
    actions: +1
    gain: 1
  }
  Upgrade: {
    actions: 0
    cards: -1
    trash: 1
    gain: 1
  }
  Vault: {
    cards: -1
    coins: +2
    churn: 2
  }
  Venture: {
    coins: +2.5
  }
  Village: {
    actions: +1
  }
  Vineyard: {actions: 0}
  "Walled Village": {
    actions: +1
    nextTurn: +0.3
  }
  Warehouse: {
    actions: 0
    churn: 3
  }
  Watchtower: {
    cards: +1.5
  }
  Wharf: {
    cards: +1
    buys: +1
    nextTurn: +3
  }
  "Wishing Well": {
    cards: +0.3
    actions: 0
  }
  Witch: {
    attack: 3
    cards: +1
  }
  Woodcutter: {
    coins: +2
    buys: +1
  }
  "Worker's Village": {
    actions: +1
  }
  Workshop: {
    gain: 1
  }
  "Young Witch": {
    attack: 2
    churn: 2
  }
}

