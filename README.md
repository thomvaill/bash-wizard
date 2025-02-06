# Bash 🧙 wizard

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Bash 🧙 wizard is a single-file Bash script that allows you to automate simple system configuration tasks on a single host.
It is designed as a lightweight alternative to tools like Ansible or Chef for smaller, mono-host setups.

## Getting Started

1. Download `wizard.sh` from the repository:
   ```bash
   curl -O https://raw.githubusercontent.com/thomvaill/bash-wizard/refs/heads/main/wizard.sh
   chmod a+x wizard.sh
   ```
2. Replace the example playbook by your implementation.
   In `wizard.sh`, look for the "playbook" section. Here you can remove or modify the sample tasks. Each "task" is just a set of functions:
   - `task_name.do()` : implementation of the task, if possible in an idempotent way
   - `task_name.when()` : to decide when the task has to run; useful for non-idempotent implementations or tasks that are too long to run everytime (eg. those which involve a download)
   - `task_name.undo()` : implementation of the task rollback
   - `task_name.explain()` : echo a one-line explanation of the task
3. Commit `wizard.sh` alongside your application or infra Git repository
4. Pull the repo and run `./wizard.sh apply` from the host you want to configure, and that's it!

## Usage

```bash
# Apply the configuration (depending on the logic you implemented, should be idempotent, ie. can be run multiple times)
./wizard.sh apply

# See which tasks are defined (and which ones have been run)
./wizard.sh list

# Rollback if things went wrong (depends on your rollback logic in the playbook)
./wizard.sh rollback

# Get full help
./wizard.sh --help
```

## Why not Ansible or another configuration management tool?

When managing a simple environment, you might want something more straightforward than a full-fledged configuration management system.
Sometimes you only need a single file to:

- Set up a development environment for your team
- Configure a one-off server without the overhead of multi-host playbooks
- Showcase a piece of infrastructure configuration in a Git repository

This is where Bash 🧙 wizard comes in:

- **Small and focused**: Just one script, easy to share or embed in another repo
- **No additional dependencies**: Pure Bash, works on most Unix-like systems. It embeds its own library (200-ish lines)
- **Familiar**: It's just pure Bash! No new domain-specific language to learn, especially for developers that are not familiar with Ansible like tools

Of course, for more complex, multi-host or production environments, you should definitely use a more robust configuration management or Infrastructure as Code tool instead ;)

## Code over Docs

In the spirit of DevOps, automation and repeatable code are at the heart of Bash 🧙 wizard. I believe in "Code over Doc":

- Your script is the documentation. Anyone can read your shell commands easily and know exactly what gets installed or configured
- Updating your "setup doc" becomes as simple as editing the script. No separate wiki pages or external docs to maintain. Just commit and ask your team to run `./wizard.sh apply` again!

## License

This project is licensed under the MIT license, Copyright (c) 2024 Thomas Vaillant. For more information see [LICENSE](LICENSE) file.
