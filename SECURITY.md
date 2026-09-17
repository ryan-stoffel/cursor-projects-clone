# Security policy

## Supported versions

This project is pre-1.0. Security fixes land on `develop` and ship with the next release on `main`.

## What this software does with secrets

- The macOS app never stores SSH keys or passwords. Remote machines use the operator's existing `~/.ssh/config`.
- Model providers are configured in `~/Library/Application Support/projectd/providers.toml` (Linux: the XDG config equivalent). API keys belong in that file or in environment variables named there. Do not commit provider keys.
- The daemon speaks the OpenAI-compatible chat completions API. No vendor SDK is linked.

## Reporting a vulnerability

Do not file a public issue for a vulnerability.

1. Use [GitHub private vulnerability reporting](https://github.com/RyanStoffel/cursor-projects-clone/security/advisories/new) if it is enabled on this repository.
2. Or email **stoffel.thomas.ryan@gmail.com** with:
   - a description of the issue
   - affected versions or commit
   - reproduction steps or a proof of concept
   - any known mitigation

You should receive an acknowledgement within a few days. Please give us time to patch before public disclosure.

## Scope

In scope: the `projectd` daemon, the `Projects` macOS app, install scripts, and CI workflows in this repository.

Out of scope: the operator's own model gateway, SSH configuration, or third-party model providers.
