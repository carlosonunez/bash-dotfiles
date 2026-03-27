## CI/CD

- ALWAYS implement a CI/CD pipeline of some kind.
- Use GitHub Actions if the project is hosted on GitHub or GitLab CI if the
  project is hosted on GitLab. (Use the repo's remote to determine the source
  control system being used.) If it's on something else, 
- Every task in the CI/CD pipeline that you build should map to a recipe in
  `make` or a command in `just`.
- Every task in the CI/CD pipeline that you create should run in a container.
