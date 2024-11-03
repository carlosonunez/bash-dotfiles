MAKEFLAGS += --silent
SHELL ?= /usr/bin/env bash

.PHONY: edit_flatcar_config view_flatcar_config view_flatcar_ignition update_flatcar_ignition \
	test setup_tests run_tests teardown_tests

view_flatcar_config: _confirm_pgp_pubkey
	sops -d $(PWD)/flatcar-config.yaml

edit_flatcar_config: _confirm_pgp_pubkey
	sops $(PWD)/flatcar-config.yaml

view_flatcar_ignition: _confirm_pgp_pubkey
view_flatcar_ignition:
	$(MAKE) view_flatcar_config | \
		docker run --rm -i quay.io/coreos/butane

update_flatcar_ignition: _confirm_pgp_pubkey
update_flatcar_ignition:
	fp=$$($(MAKE) _get_pgp_pubkey) || exit 1; \
	$(MAKE) view_flatcar_ignition | \
		sops --pgp "$$fp" --encrypt /dev/stdin --input-type=json --output-type=json > \
			$(PWD)/flatcar-config.ignition.json

test: setup_tests run_tests teardown_tests

setup_tests: _boot_flatcar_vm

run_tests:
	>&2 echo "In progress"

teardown_tests: _delete_flatcar_vm

_get_pgp_pubkey:
	docker run --rm -v "$$PWD:/data" -w /data mikefarah/yq .sops.pgp[0].fp ./flatcar-config.yaml

_confirm_pgp_pubkey:
	gpg --list-public-keys "$$($(MAKE) _get_pgp_pubkey)" &>/dev/null

_boot_flatcar_vm:
	>&2 echo "In progress"

_delete_flatcar_vm:
	>&2 echo "In progress"
