.PHONY: test test-unit test-docker

test: test-unit

test-unit:
	./tests/run.sh

test-docker:
	docker build -f tests/Dockerfile -t dotfiles-tests .
	docker run --rm dotfiles-tests
