# The front page, as a cattle container: nginx serving the built Jekyll site and
# nothing else.
#
# The site is a store path rather than a directory nginx reads at runtime, so a
# content change produces a new template and therefore a new container. There is
# no state, no secret and nothing to seed.
{ config, lib, ... }:

let
  cfg = config.services.frontpage;
in
{
  options.services.frontpage = {
    enable = lib.mkEnableOption "nginx serving houseabsolute.co.uk";

    site = lib.mkOption {
      type = lib.types.path;
      description = "The built Jekyll site, as produced by this flake's default package.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 80;
      description = ''
        Plain HTTP: the border router terminates TLS, and a backend with its own
        certificate is a backend with its own inbound path. Must match `port` in
        homelab-infra's services.yaml, which is also what the deploy health
        check polls.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;

      virtualHosts.frontpage = {
        default = true;
        listen = [{ addr = "0.0.0.0"; port = cfg.port; }];
        root = cfg.site;
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
