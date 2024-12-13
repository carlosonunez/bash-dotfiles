#!/usr/bin/env bats
@test "AdGuard Home running" {
  run faux_marcus_docker_compose ps adguard-home
  assert_success
  assert_line --regexp '.*adguard-home.*'
}

@test "AdGuard Home web interface is up" {
  run run_in_faux_marcus curl -sS -o /dev/null -w '%{http_code}' -L localhost
  assert_success
  assert_output '200'
}

@test "DNS resolvable through AdGuard Home" {
  run run_in_faux_marcus nslookup one.one.one.one 127.0.0.1
  assert_success
  assert_line 'Address: 1.1.1.1'
}

@test "DNS blocklists are working" {
  for blocked_record in push.boox.com doubleclick.net
  do
    run run_in_faux_marcus nslookup "$blocked_record"
    assert_success
    assert_line 'Address: 0.0.0.0'
  done
}
