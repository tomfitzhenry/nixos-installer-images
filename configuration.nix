{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  # One-time snapshot of https://github.com/tomfitzhenry.keys (see ./keys.nix).
  # Refresh with:  curl -s https://github.com/tomfitzhenry.keys > /tmp/keys
  trustedKeys = import ./keys.nix;
in
{
  imports = [
    # Stock minimal installer: sets stateVersion, defines the nixos and root
    # users, and enables openssh with PermitRootLogin.
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # The stock module sets isoImage.edition with lib.mkOverride 500, so a plain
  # definition (priority 1000) loses; force it to make the images identifiable.
  isoImage.edition = lib.mkForce "tom";

  # efivar 39 is broken on 32-bit; apply the two upstream fixes.
  nixpkgs.overlays = [
    (final: prev: {
      efivar = prev.efivar.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (prev.fetchpatch2 {
            name = "efivar-32bit-build-fix.patch";
            url = "https://github.com/rhboot/efivar/commit/a629c47059e76f971269b76f0f00cee2e991f427.diff?full_index=1";
            hash = "sha256-46XpN2AYPFwDCB2KORJHJD0muQDxjO820pb9cmE46KQ=";
          })

          (prev.fetchpatch2 {
            name = "efivar-32bit-format-specifiers.patch";
            url = "https://github.com/rhboot/efivar/compare/d7f55275b4e7b704cac4f36994c9267c7b2cd25e...3633172fdace9cd1b233eb997ad4128d102ae010.diff?full_index=1";
            includes = [
              "src/esl-iter.c"
              "src/efisecdb.c"
              "src/efivar.c"
            ];
            hash = "sha256-8GFFggSyN1BBoQQCW4EHRTtvChfi3Yj3VoxDIVos31s=";
          })
        ];

        meta = old.meta // {
          broken = false;
        };
      });
    })
  ];

  # Make `nix` usable out of the box on the installed system, without relying
  # on the NIX_CONFIG environment variable.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  zramSwap.enable = true;

  environment.systemPackages = with pkgs; [
    mg
    iroh-ssh
  ];

  users.users.root.openssh.authorizedKeys.keys = trustedKeys;
  users.users.nixos.openssh.authorizedKeys.keys = trustedKeys;

  # Some VM providers hand out no DHCP/SLAAC, leaving DNS unconfigured. Pin
  # Quad9 as a static fallback.
  # https://www.quad9.net/service/service-addresses-and-features/
  networking.nameservers = [
    "9.9.9.10"
    "149.112.112.10"
    "2620:fe::10"
    "2620:fe::fe:10"
  ];
}
