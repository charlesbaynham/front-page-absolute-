{
  description = "A Jekyll-based single-page website with Bootstrap";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    cattle.url = "git+https://github.com/charlesbaynham/nix-proxmox-cattle?ref=v1";
  };

  outputs = { self, nixpkgs, flake-utils, cattle }:
    let
      # The container is x86_64 whatever the machine building the site is.
      templateSystem = "x86_64-linux";

      rubyEnvFor = pkgs: pkgs.ruby_3_3.withPackages
        (ps: with ps; [ jekyll jekyll-sitemap jekyll-theme-minimal webrick ]);

      siteFor = pkgs: pkgs.stdenv.mkDerivation {
        name = "houseabsolute-site";
        src = ./.;

        buildInputs = [ (rubyEnvFor pkgs) pkgs.imagemagick ];

        buildPhase = ''
          echo "Building Jekyll site..."
          ${rubyEnvFor pkgs}/bin/jekyll build
        '';

        installPhase = ''
          mkdir -p $out
          cp -r _site/* $out/
        '';
      };

      # The Proxmox LXC template the home lab deploys. Declared here rather than
      # inside eachDefaultSystem because a template is only ever built for one
      # architecture. See README's "Deployment".
      template = cattle.lib.mkTemplate {
        inherit nixpkgs;
        system = templateSystem;
        name = "frontpage";
        modules = [
          ./frontpage.nix
          {
            services.frontpage = {
              enable = true;
              site = siteFor nixpkgs.legacyPackages.${templateSystem};
            };
          }
        ];
      };
    in
    nixpkgs.lib.recursiveUpdate template (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        rubyEnv = rubyEnvFor pkgs;
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [ rubyEnv pkgs.git pkgs.imagemagick ];

          shellHook = ''
            echo "Jekyll website development environment"
            echo ""
            echo "Available commands:"
            echo "  nix run            - Start local development server"
            echo "  nix build          - Build static site"
            echo "  jekyll serve       - Start local development server"
            echo "  jekyll build       - Build static site"
            echo ""
            echo "Get started: nix run"
          '';
        };

        # Serve app for running the development server
        apps.serve = {
          type = "app";
          program = toString (pkgs.writeShellScript "serve" ''
            ${rubyEnv}/bin/jekyll serve
          '');
        };

        apps.default = self.outputs.apps.${system}.serve;

        # Default package builds the site
        packages.default = siteFor pkgs;
      }));
}
