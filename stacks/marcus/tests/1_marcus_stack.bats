#!/usr/bin/env bats
@test "Marcus stack present on machine" {
  run run_in_faux_marcus stat "$MARCUS_STACK_REMOTE_FILE_LOCATION"
  assert_success

  want_hash="$MARCUS_STACK_REMOTE_FILE_HASH"
  got_hash=$(run_in_faux_marcus "$MARCUS_STACK_REMOTE_FILE_HASHFUNCTION $MARCUS_STACK_REMOTE_FILE_LOCATION | cut -f1 -d ' '")
  assert_equal "$want_hash" "$got_hash"
}

@test "Marcus user is a sudoer" {
  run run_in_faux_marcus sudo -v
  assert_success
}

@test "Marcus stack should be running" {
  run run_in_faux_marcus sudo systemctl status marcus-stack
  assert_success
}
