#!/usr/bin/env bats
@test "AdGuard Home running" {
  run faux_marcus_docker_compose ps -q adguard-home
  assert_success
  refute_equal "$output" ""
}
