{
  description = "Docker module for nix-darwin";

  outputs = { ... }: {
    darwinModules.docker = import ./module.nix;
  };
}
