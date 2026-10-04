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
