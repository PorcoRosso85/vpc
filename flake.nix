{
  description = "vpc: VPC-only verification via CUE manifest";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Prefer central pin (repos/flakes). Fallback to local build if missing.
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

          cueFallback = pkgs.buildGoModule rec {
            pname = "cue";
            version = "0.15.1";
            src = pkgs.fetchFromGitHub {
              owner = "cue-lang";
              repo = "cue";
              rev = "v${version}";
              hash = "sha256-0DxJK5S1uWR5MbI8VzUxQv+YTwIIm1yK77Td+Qf278I=";
            };
            vendorHash = "sha256-ivFw62+pg503EEpRsdGSQrFNah87RTUrRXUSPZMFLG4=";
            subPackages = [ "cmd/cue" ];
            ldflags = [
              "-s"
              "-w"
              "-X cuelang.org/go/cmd/cue/cmd.version=v${version}"
            ];
          };

          cue =
            if flakes ? packages && flakes.packages ? ${system} && flakes.packages.${system} ? cue-v15 then
              flakes.packages.${system}.cue-v15
            else
              cueFallback;
        in
        {
          # Single check only: "all cases run" is guaranteed inside this derivation.
          checks.fast = import ./nix/checks.nix { inherit pkgs cue self; };

          devShells.default = pkgs.mkShell {
            packages = [ cue ];
          };
        }
      );
}
