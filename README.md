# nixos-installer-images

Personalized NixOS installer ISOs for `x86_64-linux` and `aarch64-linux` that
behave like the stock minimal installer, but:

- include [`mg`](https://github.com/hboetes/mg) and
  [`iroh-ssh`](https://github.com/n0-computer/iroh-ssh),
- trust [tomfitzhenry's SSH keys](https://github.com/tomfitzhenry.keys) for the
  `root` and `nixos` users,
- are based on NixOS **stable** (`nixos-26.05`),
- are pinned by the committed `flake.lock`.

The ISOs are produced by the stock
[`installation-cd-minimal.nix`](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix)
module; this repo only layers extra packages, trusted keys, and a custom ISO
edition on top.

## Build

```console
# x86_64
nix build .#nixosConfigurations.installer-x86_64.config.system.build.isoImage

# aarch64 (requires aarch64 builder or binfmt emulation)
nix build .#nixosConfigurations.installer-aarch64.config.system.build.isoImage
```

The ISO lands in `result/iso/*.iso`, and its exact name can be inspected with:

```console
nix eval --raw .#nixosConfigurations.installer-x86_64.config.image.fileName
```

## Updating the trusted keys

`keys.nix` is a one-time snapshot of <https://github.com/tomfitzhenry.keys>.
Refresh it with:

```console
curl -s https://github.com/tomfitzhenry.keys > /tmp/keys
```

then paste the entries into `keys.nix` and commit.

## Bumping nixpkgs

The committed `flake.lock` is what actually pins nixpkgs; the input URL merely
names the `nixos-26.05` branch. Update it with:

```console
nix flake update
```

## Releases

[`.github/workflows/build.yml`](.github/workflows/build.yml) runs monthly
(`0 3 1 * *`, 03:00 UTC on the 1st) and on demand via `workflow_dispatch`. It
builds both ISOs, uploads them as artifacts, then publishes a GitHub Release
tagged `YYYY-MM`. After publishing, older releases are pruned by tag so that
**at most 3 releases remain**.

Nix is installed with
[`DeterminateSystems/determinate-nix-action`](https://github.com/DeterminateSystems/determinate-nix-action)
(flakes are enabled by default, so no extra cache configuration is needed).
Releases are published with the preinstalled [`gh`
CLI](https://cli.github.com/manual/gh_release_create): if the `YYYY-MM` release
already exists (a re-run in the same month) its assets are re-uploaded with
`gh release upload --clobber`, otherwise it is created with `gh release create
--generate-notes`.

The workflow intentionally uses only first-party `actions/*` and
DeterminateSystems actions; no other third-party actions are permitted.
[`Mic92/hestia`](https://github.com/Mic92/hestia) is an accepted exception and
could be wired in later for a shared binary cache, but it is not currently used.

x86_64 builds run on `ubuntu-latest`; aarch64 builds run natively on GitHub's
arm64 runner `ubuntu-24.04-arm`. **Native ARM runners are only free for public
repositories.** For a private repository, replace the aarch64 matrix `runner`
with `ubuntu-latest` and point Determinate Nix at a remote aarch64 builder (or
add `extra-platforms = aarch64-linux` for binfmt emulation). This is
significantly slower than a native runner.
