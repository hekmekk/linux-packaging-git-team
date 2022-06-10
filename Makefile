VERSION := 1.7.0

prefix := /usr
exec_prefix := $(prefix)
bindir := $(exec_prefix)/bin
datarootdir := $(prefix)/share
man1dir := $(datarootdir)/man/man1

bash_completion_dir := $(datarootdir)/bash-completion/completions

all: package

signing-key.asc:
ifndef GPG_SIGNING_KEY_ID
	$(error GPG_SIGNING_KEY_ID is not set)
endif
	gpg --armor --export-secret-keys $(GPG_SIGNING_KEY_ID) > `pwd`/signing-key.asc

package-build: signing-key.asc
ifndef GPG_SIGNING_KEY_ID
	$(error GPG_SIGNING_KEY_ID is not set)
endif
	docker build \
		--build-arg UID=$(shell id -u) \
		--build-arg GID=$(shell id -g) \
		--build-arg USERNAME=$(USER) \
		--build-arg VERSION=v$(VERSION) \
		--build-arg GPG_SIGNING_KEY_ID=$(GPG_SIGNING_KEY_ID) \
		-t git-team-pkg:v$(VERSION) \
		.

deb rpm: clean package-build
	mkdir -p target/$@
	chown -R $(shell id -u):$(shell id -g) target/$@
	docker run --rm -h git-team-pkg -v `pwd`/target/$@:/pkg-target git-team-pkg:v$(VERSION) fpm \
		-f \
		-s dir \
		-t $@ \
		-n "git-team" \
		-v $(VERSION) \
		-m "git-team authors" \
		--url "https://github.com/hekmekk/git-team" \
		--architecture "x86_64" \
		--license "MIT" \
		--vendor "git-team authors" \
		--description "git-team - commit message enhancement with co-authors" \
		--depends "git" \
		--deb-no-default-config-files \
		--rpm-sign \
		-p /pkg-target \
		target/bin/git-team=$(bindir)/git-team \
		target/completion/bash/git-team.bash=$(bash_completion_dir)/git-team \
		target/man/git-team.1.gz=$(man1dir)/git-team.1.gz

show-checksums: package-build
	find `pwd`/target/ -type f -exec sha256sum {} \;

package: rpm deb show-checksums

clean:
	rm -rf `pwd`/target

