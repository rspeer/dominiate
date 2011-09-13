all:
	git add .
	git commit -am "Deploying to Web from commit `cat ../.git/refs/heads/master`"
	git push origin gh-pages

