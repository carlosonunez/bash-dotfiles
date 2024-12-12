run_in_faux_marcus() {
  _ensure_running_in_docker || exit 1
  _ensure_env_configured || exit 1
  _ensure_private_key_present || exit 1

  set -x
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /secrets/private_key \
    -p "$FAUX_MARCUS_SSH_PORT" \
    "${FAUX_MARCUS_SSH_USER}@host.docker.internal" \
    "$@"
}

faux_marcus_docker_compose() {
  run_in_faux_marcus /opt/bin/docker-compose -f "$MARCUS_STACK_REMOTE_FILE_LOCATION" "$@"
}

_ensure_env_configured() {
  for k in "SSH_USER" "SSH_PORT"
  do
    env_var="FAUX_MARCUS_$k"
    test -n "${!env_var}" && break
    >&2 echo "ERROR: required env var not set: $env_var"
    exit 1
  done
}

_ensure_private_key_present() {
  assert test -f /secrets/private_key
}

_ensure_running_in_docker() {
  assert test -f /.dockerenv
}