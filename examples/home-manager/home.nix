{ username, config, pkgs, ... }:
{
  programs.home-manager.enable = true;

  home.stateVersion = "24.05";
  home.homeDirectory = "/home/${username}";
  home.username = "${username}";

  # Shoji configuration
  home.shoji = {
      enable = true;

      # Path to ssh file bundled by Shoji, relative to this file
      yaml-config = ./ssh.yaml;
  
      # If not defined: it uses $SOPS_AGE_KEY_FILE by default
      age-keyfile = "/home/myuser/.config/sops/age/shoji.txt";
  
      # Default value: ~/.ssh/
      ssh-folder = "/home/myuser/.ssh/"; 
      
      # Default value: $USER
      owner = "${username}"; 
     
      # Default value: $GROUP
      group = "users";
  
      # Default value: ~/.ssh/config
      ssh-config = "/home/myuser/.ssh/config";
  };

}

