MAKEFLAGS += --silent
SHELL ?= /usr/bin/env bash
TESTS_CONFIG := $(PWD)/tests/config.yaml
DOCKER_CLI_IMAGE := local/docker-cli
FAUX_MARCUS_COMPRESSED_BIN_FILE := $(PWD)/tests/flatcar.bin.bz2
FAUX_MARCUS_COMPRESSED_BIN_URL := https://stable.release.flatcar-linux.net/arm64-usr/3033.2.0/flatcar_developer_container.bin.bz2
FAUX_MARCUS_IMAGE_NAME := local/faux-marcus
DOCKER_COMPOSE_TEST := docker-compose -f tests/docker-compose.yaml

.PHONY: edit_flatcar_config view_flatcar_config view_flatcar_ignition update_flatcar_ignition \
	test \
	_confirm_pgp_pubkey _confirm_pgp_pubkey_for_tests \
	_get_prop_from_encrypted_file

test:
	for stage in _download_flatcar_bin _load_ssh_key_into_test_env _create_flatcar_image_from_tar; \
	do $(MAKE) "$$stage" || exit 1; \
	done
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

_download_flatcar_bin:
	$(MAKE) _confirm_flatcar_image && exit 0; \
	if ! test -f "$(FAUX_MARCUS_COMPRESSED_BIN_FILE)"; \
	then \
		>&2 echo "INFO: Downloading Flatcar Container image; please wait"; \
		curl -Lo "$(FAUX_MARCUS_COMPRESSED_BIN_FILE)" "$(FAUX_MARCUS_COMPRESSED_BIN_URL)"; \
	fi; \
	>&2 echo "INFO: Decompressing Flatcar container image; might take a few minutes"; \
	pushd "$$(dirname "$(FAUX_MARCUS_COMPRESSED_BIN_FILE)")"; \
	bunzip2 "$(FAUX_MARCUS_COMPRESSED_BIN_FILE)"; \
	rc=$$?; \
	popd; \
	exit "$$rc"

_build_docker_cli_image:
	test -n "$$(docker images --quiet | grep $(DOCKER_CLI_IMAGE))" && exit 0; \
	docker image build -t $(DOCKER_CLI_IMAGE) - < $(PWD)/tests/docker-cli.Dockerfile

_create_flatcar_image_from_tar:
	$(MAKE) _confirm_flatcar_image && exit 0; \
	$(MAKE) _build_docker_cli_image; \
	>&2 echo "INFO: Creating Flatcar container image; please wait"; \
	docker run --rm --privileged -it -v "$$(dirname "$(FAUX_MARCUS_COMPRESSED_BIN_FILE)"):/data" \
		-w /data \
		-v /var/run/docker.sock:/var/run/docker.sock \
		--entrypoint sh \
		$(DOCKER_CLI_IMAGE) \
		-c "mkdir /flatcar; \
			mount -o ro,loop,offset=2097152 flatcar.bin /flatcar; \
			dirsize=\$$(du -sk /flatcar | cut -f1); \
			tar -cp --one-file-system -C /flatcar . | pv -p -s \$${dirsize}k | \
				docker import - $(FAUX_MARCUS_IMAGE_NAME)"

_load_ssh_key_into_test_env:
	ssh_key_enc=$$(QUERY='.credentials.ssh_private_key' FILE=$(TESTS_CONFIG) $(MAKE) _get_prop_from_encrypted_file | base64 -w 0) || exit 1; \
	$(DOCKER_COMPOSE_TEST) run --entrypoint bash --rm test-env-init \
		-c "echo $$ssh_key_enc | base64 -d > /secrets/ssh_key"


_confirm_flatcar_image:
	test -n "$$(docker images --quiet $(FAUX_MARCUS_IMAGE_NAME))"

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

