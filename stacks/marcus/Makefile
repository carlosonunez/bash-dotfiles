MAKEFLAGS += --silent
SHELL ?= /usr/bin/env bash
TESTS_CONFIG := $(PWD)/tests/include/config.yaml
FAUX_MARCUS_MACHINE_NAME := faux-marcus
FAUX_MARCUS_VAGRANT_BOX := $(shell echo "$${TMPDIR:-/tmp}")/$(FAUX_MARCUS_MACHINE_NAME).box
DOCKER_COMPOSE_TEST := docker-compose -f $(PWD)/tests/include/docker-compose.yaml
PACKER_PLUGIN_QEMU_FORK_URL := https://github.com/carlosonunez/packer-plugin-qemu
PACKER_PLUGIN_QEMU_REF_URL := locally.installed/plugins/qemu

.PHONY: edit_flatcar_config view_flatcar_config view_flatcar_ignition update_flatcar_ignition \
	view_tests_config edit_tests_config \
	test \
	_confirm_pgp_pubkey _confirm_pgp_pubkey_for_tests \
	_get_prop_from_encrypted_file

test: _ensure_marcus_private_key_exists_locally _build_forked_packer_plugin_qemu _build_faux_marcus _start_faux_marcus
test:
	$(DOCKER_COMPOSE_TEST) run --rm tests; \
	rc=$$?; \
	$(MAKE) _stop_faux_marcus || true; \
	exit "$$rc";

edit_flatcar_config: _confirm_pgp_pubkey
	sops $(PWD)/flatcar-config.yaml

view_flatcar_config: _confirm_pgp_pubkey
	sops -d $(PWD)/flatcar-config.yaml

view_flatcar_ignition: _confirm_pgp_pubkey
	$(MAKE) view_flatcar_config | \
		docker run --rm -i ghcr.io/flatcar/ct:latest

# 2024-12-10: Unfortunately, host-port forwarding does not work correctly when QEMU's usermode
# networking shares the same network space as the host's.
#
# This is problematic in our case given that the Flatcar config configures NICs with static IPs
# within my home network and that these tests will usually run within it.
#
# This target modifies any static addresses and gateways found within the Flatcar config.
# This way, the home network address space doesn't have to be hardcoded anywhere.
view_flatcar_config_for_testing: _confirm_pgp_pubkey
	idx=15; \
	conf=$$($(MAKE) view_flatcar_config | sed -E 's/Gateway=.*/Gateway=10.0.2.2/g'); \
	while read -r line; \
	do \
		conf=$$(echo "$$conf" | sed "s;$$line;Address=10.0.2.$$idx/24;g"); \
		idx=$$((idx+1)); \
	done <<< "$$(echo "$$conf" | grep Address=)"; \
	echo "$$conf"

view_flatcar_ignition_for_testing: _confirm_pgp_pubkey
	$(MAKE) view_flatcar_config_for_testing | \
		docker run --rm -i ghcr.io/flatcar/ct:latest

update_flatcar_ignition: _confirm_pgp_pubkey
	fp=$$($(MAKE) _get_pgp_pubkey) || exit 1; \
	$(MAKE) view_flatcar_ignition | \
		sops --pgp "$$fp" --encrypt /dev/stdin --input-type=json --output-type=json > \
			$(PWD)/flatcar-config.ignition.json

_confirm_pgp_pubkey:
	fp=$$(QUERY='.sops.pgp[0].fp' FILE=$$PWD/flatcar-config.yaml $(MAKE) _get_prop_from_encrypted_file) || exit 1; \
	gpg --list-public-keys "$$fp" &>/dev/null

_get_prop_from_encrypted_file:
	QUERY="$${QUERY?Please provide a yq query with QUERY}"; \
	FILE="$${FILE?Please provide the sops-encrypted file with FILE}"; \
	docker run --quiet --rm -v "$$(dirname "$$FILE"):/data" \
		-w /data \
		mikefarah/yq:4.40.4 \
		"$$QUERY" /data/$$(basename "$$FILE");

_build_forked_packer_plugin_qemu:
	packer plugins installed  | grep -q packer/plugins/$(PACKER_PLUGIN_QEMU_REF_URL) && exit 0; \
	>&2 echo "INFO: Installing forked version of packer-plugin-qemu (this will be \
removed once it gets merged upstream)"; \
	trap 'rc=$$?; rm -rf /tmp/repo; exit $$rc' INT HUP EXIT; \
	git clone $(PACKER_PLUGIN_QEMU_FORK_URL) /tmp/repo && \
		pushd /tmp/repo && \
		gsed -i 's/Version = "1.1.1"/Version = "0.0.0"/g' version/version.go && \
		make build && \
		packer plugins install --path ./packer-plugin-qemu $(PACKER_PLUGIN_QEMU_REF_URL) && \
		popd

_build_faux_marcus: _ensure_packer
_build_faux_marcus:
	test -n "$(REBUILD_FAUX_MARCUS)" && rm -rf "$(FAUX_MARCUS_VAGRANT_BOX)"; \
	test -f "$(FAUX_MARCUS_VAGRANT_BOX)" && exit 0; \
	temp_ignition_file=$$(mktemp /tmp/.$(FAUX_MARCUS_MACHINE_NAME)-ignition-XXXXXX); \
	trap 'rc=$$?; rm -f "$$temp_ignition_file"; exit $$rc' INT HUP EXIT; \
	$(MAKE) view_flatcar_ignition_for_testing >"$$temp_ignition_file" || exit 1; \
	packer init $(PWD)/tests/include && \
		packer build -var "box_path=$(FAUX_MARCUS_VAGRANT_BOX)" \
			-var "ignition_file=$$temp_ignition_file" \
			$(PWD)/tests/include/machine.pkr.hcl && \
			test -f "$(FAUX_MARCUS_VAGRANT_BOX)"

_start_faux_marcus: _ensure_vagrant _ensure_vagrant_qemu_installed
	export VAGRANT_SSH_USER=$$($(MAKE) _marcus_system_user); \
	export VAGRANT_SSH_PRIVATE_KEY_PATH=$$($(MAKE) _marcus_local_private_key); \
	if test -n "$(REBUILD_FAUX_MARCUS)"; \
	then \
		$(MAKE) _stop_faux_marcus || true; \
		rm -rf $(PWD)/tests/.vagrant; \
		vagrant box list | grep -q $(FAUX_MARCUS_MACHINE_NAME) && \
		vagrant box remove "$(FAUX_MARCUS_MACHINE_NAME)"; \
	fi; \
	pushd $(PWD)/tests &>/dev/null; \
	trap 'rc=$$?; popd &>/dev/null; test "$$rc" -eq 0 || $(MAKE) _stop_faux_marcus; exit $$rc' INT HUP EXIT; \
	vagrant box list | grep -q $(FAUX_MARCUS_MACHINE_NAME) || \
		vagrant box add $(FAUX_MARCUS_VAGRANT_BOX) --name $(FAUX_MARCUS_MACHINE_NAME); \
		VAGRANT_VAGRANTFILE=$(PWD)/tests/include/Vagrantfile vagrant up --provider qemu --no-provision

_stop_faux_marcus: _ensure_vagrant _ensure_vagrant_qemu_installed
_stop_faux_marcus:
	export VAGRANT_SSH_USER=$$($(MAKE) _marcus_system_user); \
	export VAGRANT_SSH_PRIVATE_KEY_PATH=$$($(MAKE) _marcus_local_private_key); \
	pushd $(PWD)/tests &>/dev/null; \
	trap 'rc=$$?; popd &>/dev/null; exit $$rc' INT HUP EXIT; \
		VAGRANT_VAGRANTFILE=$(PWD)/tests/include/Vagrantfile vagrant halt;

_ensure_packer:
	&>/dev/null which packer && exit 0; \
	>&2 echo "ERROR: Packer not installed; please install it."; \
	exit 1

_ensure_vagrant:
	&>/dev/null which vagrant && exit 0; \
	>&2 echo "ERROR: Vagrant not installed; please install it."; \
	exit 1

_ensure_vagrant_qemu_installed:
	vagrant plugin list | grep -q qemu && exit 0; \
	vagrant plugin install vagrant-qemu

_marcus_system_user_details:
	$(MAKE) view_flatcar_config | \
		yq -r '.passwd.users[] | select(.groups[0] == "marcus-admin")'

_marcus_system_user:
	$(MAKE) _marcus_system_user_details | yq -r '.name'

_marcus_local_private_key:
	want_pubkey=$$($(MAKE) _marcus_system_user_details | yq -r .ssh_authorized_keys[0]); \
	while read -r key_file; \
	do \
		got_pubkey=$$(ssh-keygen -yf "$$key_file"); \
		if test "$$want_pubkey" == "$$got_pubkey" ; \
		then echo "$$key_file" && exit 0; \
		fi; \
	done <<< "$$(grep -Elr 'BEGIN (OPENSSH|RSA) PRIVATE' $(HOME)/.ssh)";

_ensure_marcus_private_key_exists_locally:
	test -n "$$($(MAKE) _marcus_local_private_key)" && exit 0; \
	>&2 echo "ERROR: No local private keys found that match Marcus's public key in the Flatcar config."; \
	exit 1; \
