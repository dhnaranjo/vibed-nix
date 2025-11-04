{
  description = "A flake with cowsay";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        default = pkgs.cowsay;
        cowsay = pkgs.cowsay;
      };

      apps.${system} = {
        default = {
          type = "app";
          program = "${pkgs.cowsay}/bin/cowsay";
        };
        cowsay = {
          type = "app";
          program = "${pkgs.cowsay}/bin/cowsay";
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.cowsay ];
      };
    };
}
