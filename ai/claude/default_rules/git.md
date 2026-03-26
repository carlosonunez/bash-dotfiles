# General Rules

- ALWAYS use the `/commit` command to GPG sign your commits.
  Use either the email address defined by the `$GIT_AUTHOR_EMAIL` environment
  variable or `13461447+carlosonunez@users.noreply.github.com` to sign these
  commits. DO NOT USE ANY OTHER KEYS ON THE SYSTEM.
- Always do a rebase whenever you pull in new changes from a remote.
- Commits should be as atomic as possible.
- Use feature branches for active work, then merge them into `main` through a
  GitHub pull request.
- Changes should be committed as atomically as possible. Avoid large (>200 LOC)
  change sets.
- DO NOT use the `gh` utility unless told to explicitly do so.
- DO NOT RESOLVE MERGE CONFLICTS AUTOMATICALLY. Step through any merge conflicts
  interactively with me.

# Work Categories

These are used as prefixes to commits and branches outside of `main`:

- `feat`: Feature work.
- `doc`: Changing documentation, like READMEs and other markdown files.
- `fix`: Fixes for existing features. (Use `sec` for security-related fixes.)
- `sec`: Security work, like patching vulnerabilities.
- `chore`: Updating things like Docker Compose YAMLs, Justfiles, etc **UNLESS**
  they relate to CI/CD changes.
- `ci`: Updating things related to build and deployment, like GitHub Actions
        tasks and Docker Compose services that affect deployment.

# Branch Naming

All branches outside of `main` should be prefixed with one one of the categories shown
in the "Work Categories" section and suffixed with a short (less than five
words) description of the feature being built separated by a slash.

For example, if a new authentication mechanism is being added, its branch should
be called `feat/new-auth-mechanism`.

# Commit message etiquette

- The first line of ALL commits should start with one of the categories in the
  "Work Categories" section followed by a short description separated by a
  colon. It MUST not be longer than 50 characters.

- More context that needs to be provided to the commit can be added underneath
  the first line in the commit body. Make this as long as you feel is necessary
  to describe what you did.

- EVERY commit must have this header:

  ```
  Co-authored-by: Carlos Nunez <$EMAIL_ADDRESS>
  ```

  Replace `$EMAIL_ADDRESS` with whichever of these comes first:

  - The `user.email` property in `$PWD/.gitconfig`
  - The `user.email` property in `~/.gitconfig`
  - The `$GIT_EMAIL_ADDRESS` environment variable
  - The `$DEFAULT_GIT_EMAIL_ADDRESS` environment variable
  - `13461447+carlosonunez@users.noreply.github.com`

  **DO NOT CONTINUE IF YOU CANNOT FIND A VALID EMAIL ADDRESS TO USE.**
