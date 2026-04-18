
# user (user)

Create a user and group with the specified UID/GID.

## Example Usage

```json
"features": {
    "ghcr.io/xorpse/devcontainer-features/user:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| username | Username of the user | string | automatic |
| userUid | UID for the user | string | automatic |
| userGid | GID for the user | string | automatic |
| sudo | Grant the user passwordless sudo access | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
