## Testing

- Please try to use `stretchr/testify` whenever possible.
- If a function has many similar test cases, please find a way of running them as
  a group. For example, these tests:

  ```golang
  func TestFooDoesAThing(t *testing.T) {
    want := 1
    got := foo("bar")
    if want != got {
      t.Fail("wanted %s, got %s", want, got)
    }
  }

  func TestFooDoesAnotherThing(t *testing.T) {
    want := 2
    got := foo("baaz")
    if want != got {
      t.Fail("wanted %s, got %s", want, got)
    }
  }

  func TestFooDoesYetAnotherThing(t *testing.T) {
    want := 3
    got := foo("quux")
    if want != got {
      t.Fail("wanted %s, got %s", want, got)
    }
  }
  ```

  Should be consolidated like this:

  ```golang
  type FooTest struct {
    TestName string
    Arg string
    Want int
  }

  func (f *FooTest) RunTest(t *testing.T) int {
    got := foo(t.Arg)
    assert.Equal(t, f.Want, got, "[%s] failed: wanted: %s, got: %s",
      t.TestName, t.Want, got)
  }

  func TestFoo(t *testing.T) {
    tests := []FooTests{
      {TestName: "foo_does_a_thing", Arg: "bar", Want: 1},
      {TestName: "foo_does_another_thing", Arg: "baz", Want: 2},
      {TestName: "foo_does_yet_another_thing", Arg: "quux", Want: 3},
    }
    for _, test := range tests {
      test.RunTest(t)
    }
  }
  ```

# Building

- Code should work across MacOS, Windows and Linux on `amd64` and `arm64`
  architectures.
