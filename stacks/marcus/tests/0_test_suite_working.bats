#!/usr/bin/env bats
@test "Faux Marcus test suite operational" {
  run run_in_faux_marcus "echo Hello!"
  assert_success
}
