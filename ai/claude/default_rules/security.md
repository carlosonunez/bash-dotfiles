## Config files

- If you need to create a config file for anything, ALWAYS name it
  `config.yaml` and place it at the root of the project repository.
- **ALWAYS** encrypt `config.yaml` files that you create with `sops` with these
  rules:
    - You can install `sops` if it's missing on the system.
    - Create a GPG key for each project a `config.yaml` file is created for and
      encrypt it with this key. (I'll use the `/gpg_key` command to get the
      private key and `/gpg_fp` command to get that key's fingerprint.)
    - Only encrypt config keys that have an `#encrypted` comment attached to them.
    - If it looks sensitive (like a cloud provider credential, Kubernetes secret
      or Kubeconfig), make sure that it's encrypted.

## Gitleaks

- **ALWAYS** run `gitleaks` before committing ANY changes to Git! Use a
  `commit-msg` Git client-side hook.
- `gitleaks` can be installed onto the system.
- Run `gitleaks dir` AND `gitleaks git`.
