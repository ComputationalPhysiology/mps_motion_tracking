.PHONY: clean clean-test clean-pyc clean-build docs help
.DEFAULT_GOAL := help

define BROWSER_PYSCRIPT
import os, webbrowser, sys

from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

lint: ## check style with flake8
	python -m flake8 mps_motion_tracking tests

type: ## Run mypy
	python3 -m mypy mps_motion_tracking tests

test: ## run tests on every Python version with tox
	python3 -m pytest -v -cov=mps_motion_tracking tests

docs: ## generate Sphinx HTML documentation, including API docs
	rm -f docs/mps_motion_tracking.rst
	rm -f docs/modules.rst
	pandoc README.md -o docs/readme.rst
	pandoc HISTORY.md -o docs/history.rst
	pandoc CONTRIBUTING.md -o docs/contributing.rst
	pandoc AUTHORS.md -o docs/authors.rst
	sphinx-apidoc -o docs/ mps_motion_tracking
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	# $(BROWSER) docs/_build/html/index.html
	# python -m http.server --directory docs/_build/html

servedocs: docs ## compile the docs watching for changes
	watchmedo shell-command -p '*.rst' -c '$(MAKE) -C docs html' -R -D .

release: dist ## package and upload a release
	python3 -m twine upload -u ${PYPI_USERNAME} -p ${PYPI_PASSWORD} dist/*

dist: clean ## builds source and wheel package
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean ## install the package to the active Python's site-packages
	python3 -m pip install .

dev: clean ## Just need to make sure that libfiles remains
	python3 -m pip install -r requirements_dev.txt
	python3 -m pip install -e ".[all]"
	pre-commit install

bump:
	bump2version patch

notebook:
	python -m pip install jupyter, rise
	jupyter-nbextension install rise --py --sys-prefix
	jupyter nbextension enable rise --py --sys-prefix
