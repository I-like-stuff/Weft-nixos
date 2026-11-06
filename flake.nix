{
  description = "Nix flake for Weft voxel sandbox engine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
        inherit system;
      });
    in {
      packages = forAllSystems ({ pkgs, system }: {
        weft = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.weft;
      });

      apps = forAllSystems ({ system, ... }: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/weft";
        };
      });

      overlays.default = final: prev: {
        weft = final.callPackage ./package.nix { };
      };

      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.weft;
        in {
          options.programs.weft = {
            enable = lib.mkEnableOption "Weft voxel sandbox engine";
            package = lib.mkPackageOption self.packages.${pkgs.stdenv.hostPlatform.system} "weft" { };
            openFirewall = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Open default multiplayer server ports (27182 TCP/UDP) in the firewall.";
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
            hardware.graphics.enable = lib.mkDefault true;
            networking.firewall = lib.mkIf cfg.openFirewall {
              allowedTCPPorts = [ 27182 ];
              allowedUDPPorts = [ 27182 ];
            };
          };
        };
    };
}
