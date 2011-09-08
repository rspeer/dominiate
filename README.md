The Minion
==========

The Minion is a Dominion simulator, in which you can program bots to follow
strategies that you define and see which one wins.

It is inspired by Geronimoo's Dominion Simulator. It shares the feature that,
to define many possible strategies, you may simply list cards and conditions in
which to buy them in priority order.

The code is meant to be open and extensible. Many other aspects of a strategy
can be overridden, including its preferences for how to play actions. If this
system doesn't allow you to define the strategy you want and you're okay with
writing more code, I encourage you to fork the simulator and change it so that
it does.

The Minion is written in CoffeeScript-flavored node.js. This means it runs
inside a JavaScript interpreter, but uses a nicer syntax than JavaScript for
defining both its code and its AI preferences. With some slight changes (which
I haven't made yet), it should be able to run natively in a Web browser!

Documentation
-------------
The `docs` directory contains documentation in the "literate programming" style
-- that is, it shows you the code in parallel with explanations of what it
does.

Installation
------------
This isn't yet end-user code. You need a reasonable development environment
with a command line to use the Minion.

First, acquire node.js (v0.4 or later) and npm (the Node Package Manager).  The
best way to do this differs by operating system and changes a lot.

Enable CoffeeScript by running `sudo npm-g install coffee-script` (or whatever
the equivalent is on Windows). Now node.js will understand CoffeeScript source
files.

Running "./play.coffee bot1 bot2" will load the two bots with the
specified names and play them against each other. For example:

    ./play.coffee strategies/BigMoney.coffee strategies/ChapelWitch.coffee

Compilation to JavaScript
-------------------------
This shouldn't be necessary at this point, but you can convert the Minion to
not-very-readable JavaScript code by running:

    coffee -c *.coffee

Roadmap
-------
This is a development release that's probably only usable by certain kinds of
programmers who are also Dominion players. Short-term planned features include:

- A way to run the Minion in your Web browser, without being a Node haxor
- Comparing the win rates of strategies over multiple runs
- don't buy cards that make you instantly lose
- Almost all cards implemented

Longer term plans:

- Hook into Golem, in order to buy a card based on the situation
- Simulate the effects of playing cards (to a shallow depth) in order to
  choose an action.
- Calculate the game-theoretic implications of a buy, to implement the
  Penultimate Province Rule.

Things I never plan to implement without help:

- Tricks with multi-revealing Secret Chamber
- Outpost
- Possession

