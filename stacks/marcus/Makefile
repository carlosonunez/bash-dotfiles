MAKEFLAGS += --silent
SHELL ?= /usr/bin/env bash
TESTS_CONFIG := $(PWD)/tests/config.yaml
DOCKER_COMPOSE_TEST := docker-compose -f tests/docker-compose.yaml

.PHONY: edit_flatcar_config view_flatcar_config view_flatcar_ignition update_flatcar_ignition \
	test \
	_confirm_pgp_pubkey _confirm_pgp_pubkey_for_tests \
	_get_prop_from_encrypted_file

test:
	$(DOCKER_COMPOSE_TEST) run --rm tests

view_tests_config: _confirm_pgp_pubkey_for_tests
	sops -d $(TESTS_CONFIG)

edit_tests_config: _confirm_pgp_pubkey_for_tests
	sops $(TESTS_CONFIG)

view_flatcar_config: _confirm_pgp_pubkey
	sops -d $(PWD)/flatcar-config.yaml

edit_flatcar_config: _confirm_pgp_pubkey
	sops $(PWD)/flatcar-config.yaml

view_flatcar_ignition: _confirm_pgp_pubkey
	$(MAKE) view_flatcar_config | \
		docker run --rm -i quay.io/coreos/butane

update_flatcar_ignition: _confirm_pgp_pubkey
	fp=$$($(MAKE) _get_pgp_pubkey) || exit 1; \
	$(MAKE) view_flatcar_ignition | \
		sops --pgp "$$fp" --encrypt /dev/stdin --input-type=json --output-type=json > \
			$(PWD)/flatcar-config.ignition.json

_confirm_pgp_pubkey:
	fp=$$(QUERY='.sops.pgp[0].fp' FILE=$$PWD/flatcar-config.yaml $(MAKE) _get_prop_from_encrypted_file) || exit 1; \
	gpg --list-public-keys "$$fp" &>/dev/null

_confirm_pgp_pubkey_for_tests:
	fp=$$(QUERY='.sops.pgp[0].fp' FILE=$(TESTS_CONFIG) $(MAKE) _get_prop_from_encrypted_file) || exit 1; \
	gpg --list-public-keys "$$fp" &>/dev/null

_get_prop_from_encrypted_file:
	QUERY="$${QUERY?Please provide a yq query with QUERY}"; \
	FILE="$${FILE?Please provide the sops-encrypted file with FILE}"; \
	docker run --quiet --rm -v "$$(dirname "$$FILE"):/data" \
		-w /data \
		mikefarah/yq:4.40.4 \
		"$$QUERY" /data/$$(basename "$$FILE");

