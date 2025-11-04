{
  description = "A flake with cowsay and devshell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      imports = [
        inputs.devshell.flakeModule
      ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages = {
          default = pkgs.cowsay;
          cowsay = pkgs.cowsay;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.cowsay}/bin/cowsay";
          };
          cowsay = {
            type = "app";
            program = "${pkgs.cowsay}/bin/cowsay";
          };
        };

        devshells.default = {
          name = "vibed-nix";

          packages = [
            pkgs.cowsay
          ];

          commands = [
            {
              name = "cowsay";
              help = "Say things with a cow";
              command = "${pkgs.cowsay}/bin/cowsay \"$@\"";
            }
          ];

          motd = ''
            {202}🐄 Welcome to vibed-nix development environment!{reset}

            Available commands:
            $(commands)
          '';
        };
      };
    };
}
