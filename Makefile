.PHONY: serve
serve:
	docker run --rm -it -v "$$PWD:/src" -p 4000:4000 ruby:3.3.0 /bin/bash -c "cd /src && bundle install && bundle exec jekyll serve -H 0.0.0.0"

.PHONY: serve-drafts
serve-drafts:
	docker run --rm -it -v "$$PWD:/src" -p 4000:4000 ruby:3.3.0 /bin/bash -c "cd /src && bundle install && bundle exec jekyll serve -H 0.0.0.0 --drafts"
