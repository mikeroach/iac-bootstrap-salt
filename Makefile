# Jinja variables and spaces from inline file content in states cause errors.
# TODO: Find a decent Salt linter.

success := "\033[0;32mLookin' good. 👍\033[0m"

lint:
	yamllint `find . -name \*.sls` && echo $(success)
