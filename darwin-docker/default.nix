{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.virtualisation.docker;

  vmName = "darwin-docker";
  hostSshPort = 31023;

  dockerPort = cfg.dockerPort;
  linux-builder = cfg.package;

  dockerConfig = import ./config.nix {
    name = vmName;
    inherit dockerPort;
  };
  buildDaemonizedVM = pkgs.callPackage ../buildDaemonizedVM.nix { inherit linux-builder; };

  vm = buildDaemonizedVM {
    inherit vmName hostSshPort;
    inherit (cfg) workingDirectory ephemeral;
    modules = [
      dockerConfig
      cfg.config
    ];
  };
  dockerHostVariable = {
    environment.variables.DOCKER_HOST = "tcp://127.0.0.1:${dockerPort}";
  };
in
with lib;
{
  options.virtualisation.docker = {
    enable = mkEnableOption "enable Docker on darwin via a VM running in the background";

    package = mkOption {
      type = types.package;
      default = pkgs.darwin.linux-builder;
      defaultText = "pkgs.darwin.linux-builder";
      description = ''
        This option specifies the Linux builder to use.
        Linux builder is the underlying VM on which Darwin docker builds.
      '';
    };

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

    workingDirectory = mkOption {
      type = types.str;
      default = "/var/lib/${name}";
      description = ''
        The working directory of the darwin-docker daemon process.
      '';
    };

    dockerHostVariable = mkEnableOption {
      default = true;
      description = ''
        set DOCKER_HOST="tcp://127.0.0.1:${dockerPort}" for all shell sessions
      '';
    };

    ephemeral = mkEnableOption ''
      wipe the VM's filesystem on every restart.

      This is disabled by default as maintaining the VM's filesystem keeps all docker images
      etc. from downloading each time the VM is started.
    '';
  };

  config = mkIf cfg.enable vm // (mkIf cfg.dockerHostVariable dockerHostVariable);
}
