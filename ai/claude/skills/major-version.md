---
description: Tags a commit with a new major version.
---

Does nothing if the code being committed is not in the `main` branch.

If it is, the following occurs:

- STOPS if no changes to actual code (like `.go` files in Golang, `.rb` files in
  Ruby, etc) have been made between the last major version and this commit.
- ALL tests are executed; stops on any failures.
- An EMPTY commit with the rules shown below is created and pushed:
  - The subject is prefixed with the new version and contains a short (less than
    50 characters) summary of the differences between this major version and the
    last major version
  - The body contains a paragraph describing the diff between this major version
    and the last one, then, afterwards, a summarized list of those changes.
- The empty commit created above is tagged with the newest major version.
