
# Common Utilities (common-utils)

Installs common command line utilities, Oh My Zsh!, and sets up a non-root user. Includes GNU/POSIX utilities and glibc locale support for Wolfi-based containers.

## Example Usage

```json
"features": {
    "ghcr.io/xorpse/devcontainer-features/common-utils:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installZsh | Install zsh | boolean | true |
| configureZshAsDefaultShell | Configure zsh as the default shell for the user | boolean | false |
| installOhMyZsh | Install Oh My Zsh! | boolean | true |
| installOhMyZshConfig | Install the default Oh My Zsh! configuration (template .zshrc) | boolean | true |
| upgradePackages | Upgrade existing packages | boolean | true |
| username | Username for the non-root user | string | automatic |
| userUid | UID for the non-root user | string | automatic |
| userGid | GID for the non-root user | string | automatic |
| sudo | Grant the user passwordless sudo access | boolean | true |
| installSsl | Install OpenSSL libraries | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/xorpse/devcontainer-features/blob/main/src/common-utils/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
