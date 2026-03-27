- **ALWAYS** ask me before installing any packages or modifying any files
  outside of my home directory.
- **ALWAYS** use test-driven development, regardless of the language.
- **ALWAYS** start with a plan and have me confirm before developing any
  features.
- **ALWAYS** write your plans to `.claude/plan` in the repository root.

## Tech Stack

- Always default to Golang unless stated otherwise.
- Shell scripts are ALWAYS in Bash, no exceptions.

## Command Runners

- ALWAYS use `casey/just`.

## Logging

- **ALWAYS** use a logging library regardless of tech stack
- **ALWAYS** implement these logging levels:
  - INFO: For informational messages. Should be no more than a sentence long.
  - WARN: For warnings. Should be no more than a sentence long.
  - ERROR: For errors. These can be as long as needed to help the user solve the
    problem, kind of like `hashicorp/terraform`'s error messages.
  - DEBUG: For debug messages that users can use for troubleshooting.
  - TRACE: For really low-level operations beneficial for contributors and users
    submitting issues/pull requests.
- The logging level should ALWAYS be settable through the `LOG_LEVEL`
  environment variable.

## Versioning

- ALWAYS use semver unless directed otherwise.
- Use these guidelines to determine when to bump versions:
  - **Major**: Large, backwards-incompatible changes. NEVER set
    automatically. ALWAYS done by running `/major-version`.
  - **Minor**: New features that don't break backwards-compatibility.
  - **Patch**: Small changes to existing features.
- When building CLI tools, ALWAYS add a `version` subcommand that prints the
  version of the tool in this format:

  ```
  $TOOL_NAME version $SEM_VER (Commit: $COMMIT_SHA_AT_VERSION, Last Updated:
  $DATE_OF_COMMIT)
  ```
- When building GUI tools, the version of the component that creates the
  interface should be shown on the bottom right side of the page like this:

  ```
  $CURRENT_YEAR $TOOL_NAME (version: $SEM_VER)
  ```

  (I might ask you to hide this depending on what's built)
- ALWAYS tag the commit with the version number you assign whenever you update
  the version, but ONLY AFTER the code gets merged into `main`.
