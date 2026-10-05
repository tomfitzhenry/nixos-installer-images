{
  description = "Personalized NixOS installer images (x86_64, aarch64 and armv7l)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { nixpkgs, ... }:
    let
      # hostPlatform is set per-configuration via a module; the `system`
      # argument to nixosSystem is a legacy alias.
      mkInstaller =
        hostPlatform:
        nixpkgs.lib.nixosSystem {
          modules = [
            ./configuration.nix
            { nixpkgs.hostPlatform = hostPlatform; }
          ];
        };
    in
    {
      nixosConfigurations = {
        installer-x86_64 = mkInstaller "x86_64-linux";
        installer-aarch64 = mkInstaller "aarch64-linux";
        installer-armv7l = mkInstaller "armv7l-linux";
      };
    };
}
