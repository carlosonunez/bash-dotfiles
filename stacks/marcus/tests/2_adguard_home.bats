#!/usr/bin/env bats
@test "AdGuard Home running" {
  run faux_marcus_docker_compose ps adguard-home
  assert_success
  assert_output 'adguard-home'
}
