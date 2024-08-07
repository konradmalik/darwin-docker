{ dockerPort }:
{
  users.users.builder = {
    extraGroups = [ "docker" ];
  };

  virtualisation = {
    docker = {
      enable = true;
      daemon.settings = {
        hosts = [ "tcp://0.0.0.0:${dockerPort}" ];
      };
    };
    forwardPorts = [
      {
        from = "host";
        guest.port = dockerPort;
        host.port = dockerPort;
      }
    ];
  };
  networking.firewall.allowedTCPPorts = [ dockerPort ];
}
