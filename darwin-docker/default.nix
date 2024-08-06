{ config, lib, ... }:

let
  cfg = config.virtualisation.docker;
  dockerPort = cfg.dockerPort;
  dockerModules = [
    (import ./config.nix { inherit dockerPort; })
    cfg.config
  ];
  builderWithOverrides = config.nix.linux-builder.package.override (previousArguments: {
    modules = previousArguments.modules ++ dockerModules;
  });
in
with lib;
{
  options.virtualisation.docker = {
    enable = mkEnableOption "enable Docker on darwin via linux-builder VM running in the background";

    dockerPort = mkOption {
      type = types.number;
      default = 2375;
      description = ''
        TCP port over which to serve docker daemon api to the host.
      '';
    };

    config = mkOption {
      type = types.deferredModule;
      default = { };
      example = literalExpression ''
        ({ pkgs, ...}:

        {
          virtualisation = {
            cores = 4
            memorySize = 8192

            docker = {
              autoPrune = {
                enable = true;
                flags = [ "--all" ];
                dates = "weekly";
              };
            };
          };
        })
      '';
      description = ''
        This option specifies extra NixOS configuration for the VM.
        Useful to fine-tune docker options and VM specs.
      '';
    };

    dockerHostVariable = mkEnableOption {
      default = true;
      description = ''
        set DOCKER_HOST="tcp://127.0.0.1:${dockerPort}" for all shell sessions
      '';
    };
  };

  config =
    mkIf cfg.enable {
      nix = {
        linux-builder = {
          enable = true;
          package = builderWithOverrides;
        };
      };
    }
    // (mkIf cfg.dockerHostVariable {
      environment.variables.DOCKER_HOST = "tcp://127.0.0.1:${dockerPort}";
    });
}
