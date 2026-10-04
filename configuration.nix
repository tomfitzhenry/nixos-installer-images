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

  environment.systemPackages = with pkgs; [
    mg
    iroh-ssh
  ];

  users.users.root.openssh.authorizedKeys.keys = trustedKeys;
  users.users.nixos.openssh.authorizedKeys.keys = trustedKeys;
}
