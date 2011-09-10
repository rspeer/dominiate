all: css web-coffee

web-coffee:
	coffee -c -j web/playWeb.js playWeb.coffee basicAI.coffee cards.coffee gameState.coffee
	coffee -c web/multiLog.coffee

css:
	lessc web/dominiate.less web/dominiate.css
