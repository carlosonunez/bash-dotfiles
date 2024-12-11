#!/usr/bin/env bats
@test "Faux Marcus test suite operational" {
  assert_success "$(run_in_faux_marcus "echo 'Hello!'")"
}
