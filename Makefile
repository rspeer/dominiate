all: css web-coffee web-strategies

web-coffee:
	coffee -c -j web/playWeb.js playWeb.coffee basicAI.coffee cards.coffee gameState.coffee
	coffee -c web/multiLog.coffee
	coffee -c web/scoreTracker.coffee

web-strategies:
	coffee compileStrategies.coffee

css:
	lessc web/dominiate.less web/dominiate.css

docs:
	docco *.coffee

