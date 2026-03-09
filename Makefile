.PHONY: test test-policies test-templates

test: test-policies test-templates

test-policies:
	./buildscripts/test_weaver_policies.sh

test-templates:
	./buildscripts/test_weaver_templates.sh

install-prettier:
	npm install --save-dev prettier

markdown-fmt: install-prettier
	npx prettier --write "**/*.md"
