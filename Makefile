all: css web-coffee web-strategies

web-coffee:
	coffee -c -j web/playWeb.js playWeb.coffee basicAI.coffee cards.coffee gameState.coffee
	coffee -c web/multiLog.coffee
	coffee -c web/scoreTracker.coffee
	coffee -c web/grapher.coffee

web-strategies:
	coffee compileStrategies.coffee

css:
	lessc web/dominiate.less web/dominiate.css

doc:
	docco *.coffee

web-deploy: web-coffee web-strategies css
	cd gh-pages; git pull -f origin gh-pages
	cp -a web/* gh-pages/
	cp -a docs/* gh-pages/docs/
	cd gh-pages; make
