# Shared repository policy

This repository ships portable desktop features and curated defaults. Machine repairs stay on the user's computer: faulty-key suppression, device identifiers, sleep/lid workarounds, boot and disk tuning, credential-storage overrides, individual display scales, and personal application profiles are not shared templates.

The local desktop configuration is separate from the repository's `home/` tree. Publish deliberate source changes rather than copying the whole home directory or replacing templates with live settings. Use `@HOME@` for template paths and discover hardware at runtime. Hardware-profile controls are reusable, explicitly enabled features that probe supported drivers; they do not contain a user's measured hardware state.

`bash scripts/check.sh` runs the publication guard, portability checks and feature tests. The guard checks tracked and unignored new files for prohibited personal configuration paths, machine-specific template content, and common credential formats. It also rejects those files if force-added despite `.gitignore`. A pattern scan cannot guarantee the absence of every kind of private information, so review new files and screenshots before publishing.

Runtime reports, backups, usage databases, authentication files and app profiles stay outside source control. Repository screenshots must show demonstration content without private chats or account information.

Removing a file from the current branch does not erase earlier commits. Historical cleanup requires a separate coordinated history rewrite; normal publication checks leave existing Git history intact.

Enable the local push guard in a clone with `git config core.hooksPath .githooks`. It scans the committed tree before pushing, so an uncommitted deletion cannot conceal a prohibited committed file. This repository's working clone has that hook enabled. GitHub CI runs the same guard as part of validation.
