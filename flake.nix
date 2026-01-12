{
  description = "vpc: VPC-only verification via CUE manifest";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Local dev path. In CI, pin this to a git URL instead.
    flakes = {
      url = "github:PorcoRosso85/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      flakes,
    }:
    flake-utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
      ]
      (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          cue = flakes.packages.${system}.cue-v15;
        in
        {
          checks.manifest-cue = pkgs.runCommand "vpc-manifest-cue" { nativeBuildInputs = [ cue ]; } ''
            cue eval -c -e manifest ${self}/manifest.cue >/dev/null
            touch $out
          '';

          devShells.default = pkgs.mkShell {
            packages = [ cue ];
          };
        }
      );
}
