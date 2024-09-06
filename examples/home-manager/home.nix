{ config, pkgs, ... }:

{
  home.username = "myuser";

  home.shoji = {
    enable = true;
    yaml-config = ./ssh.yaml;
    age-keyfile = "/root/keys/age.txt";

# Other options availables but defined with nice default values
#    ssh-folder = "/home/myuser/.ssh/"; 
#    owner = "myuser";
#    group = "myuser";
#    ssh-config = "/home/myuser/.ssh/config";

  };
}

