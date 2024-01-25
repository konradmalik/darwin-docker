{ lib, writeShellScript, linux-builder }:
{ vmName, modules, workingDirectory, hostSshPort, ephemeral }:

let
  builderWithOverrides = linux-builder.override
    {
      modules = [
        ({
          # to not conflict with docker-builder
          virtualisation.darwin-builder.hostPort = hostSshPort;
        })
      ] ++ modules;
    };

  # create-builder uses TMPDIR to share files with the builder, notably certs.
  # macOS will clean up files in /tmp automatically that haven't been accessed in 3+ days.
  # If we let it use /tmp, leaving the computer asleep for 3 days makes the certs vanish.
  # So we'll use /run/org.nixos.${vmName} instead and clean it up ourselves.
  script = writeShellScript "${vmName}-start" ''
    export TMPDIR=/run/org.nixos.${vmName} USE_TMPDIR=1
    rm -rf $TMPDIR
    mkdir -p $TMPDIR
    trap "rm -rf $TMPDIR" EXIT
    ${lib.optionalString ephemeral ''
      rm -f ${workingDirectory}/${builderWithOverrides.nixosConfig.networking.hostName}.qcow2
    ''}
    ${builderWithOverrides}/bin/create-builder
  '';
in
{
  system.activationScripts.preActivation.text = ''
    mkdir -p ${workingDirectory}
  '';

  launchd.daemons.${vmName} = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/bin/wait4path /nix/store &amp;&amp; exec ${script}"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      WorkingDirectory = workingDirectory;
    };
  };
}
