{config, ...} :
{
# Shoji configuration
  shoji.enable = true;
  shoji.ssh-folder = "/root/.ssh";
  shoji.owner = "root";
  shoji.group = "users";
  shoji.age-keyfile = "/root/.sops/age/keys.txt";
  shoji.ssh-config = "/root/.ssh/config";
  shoji.yaml-config =  ./ssh.yaml;
}

