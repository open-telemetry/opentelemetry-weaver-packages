.PHONY: test test-policies test-templates update-test-output chlog-update

test: test-policies test-templates

test-policies:
	./buildscripts/test_weaver_policies.sh

test-templates:
	./buildscripts/test_weaver_templates.sh

# Regenerate every template test's expected/ from the freshly generated output.
update-test-output:
	UPDATE_EXPECTED=1 ./buildscripts/test_weaver_templates.sh

# Cut the Unreleased section of CHANGELOG.md into a release section, e.g.
# make chlog-update VERSION=0.1.0
chlog-update:
	./buildscripts/update_changelog.sh $(VERSION)

install-prettier:
	npm install --save-dev prettier

markdown-fmt: install-prettier
	npx prettier --write "**/*.md"
