{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { pkgs, lib, ... }:
        let
          sk9 = pkgs.vimUtils.buildVimPlugin {
            name = "sk9";
            src = lib.cleanSource ./.;
          };
          vim-customized = pkgs.vim-full.customize {
            vimrcConfig = {
              customRC = ''
                set number
                syntax on

                set textwidth=0
                set autoindent
                set smartindent
                set smarttab
                filetype plugin on
                filetype plugin indent on

                set tabstop=4 shiftwidth=4 expandtab

                if has("autocmd")
                  autocmd filetype vim setlocal tabstop=2 shiftwidth=2 expandtab
                  autocmd filetype nix setlocal tabstop=2 shiftwidth=2 expandtab
                  autocmd filetype markdown setlocal tabstop=2 shiftwidth=2 expandtab
                  autocmd filetype json setlocal tabstop=2 shiftwidth=2 expandtab
                endif
              '';
              packages.testingPackage = {
                start = [ pkgs.vimPlugins.vim-themis ];
              };
            };
          };
          test-runner = pkgs.stdenv.mkDerivation {
            name = "sk9_test-runner";
            src = lib.cleanSource ./.;

            buildInputs = [
              pkgs.vimPlugins.vim-themis
              vim-customized
            ];

            buildPhase = ''
              mkdir -p $out/share
              themis -r | tee $out/share/themis-result.txt
            '';
          };
        in
        {
          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.actionlint.enable = true;
            programs.mdformat.enable = true;
          };

          checks = {
            inherit sk9 test-runner;
          };

          packages = {
            inherit sk9;
            default = sk9;
          };

          devShells.default = pkgs.mkShell {
            packages = [
              vim-customized
              pkgs.vimPlugins.vim-themis
              pkgs.nil
            ];
          };
        };
    };
}
