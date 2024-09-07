{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.home.shoji;
  goProgram = pkgs.buildGoModule rec {
    pname = "shoji";
    name = "shoji";
    version = "0.0.1";

    src = pkgs.fetchFromGitHub {
      owner = "AdoPi";
      repo = "${pname}";
      rev = "v${version}";
      hash = "sha256-jGozqQYY/FH+tMPJ+3xxjuZ8DPjb01F0cHKLnrsebls=";
    };
    vendorHash = "sha256-uvpMGk0MbjR7kGRL2K1uP1vH30TAuz/ULEjObW6udyA=";
  };

in
{
  options.home.shoji = {
    enable = mkEnableOption "shoji";

    ssh-folder = mkOption {
      type = types.str;
      default = "/home/${config.home.username}/.ssh/";
      description = "Keys directory";
    };

    owner = mkOption {
      type = types.str;
      default = "${config.users.users.${config.home.username}.uid}";
      description = "Owner, it is recommended to get the group name from `config.users.users.<?name>.name` to avoid misconfiguration ";
    };

    group = mkOption {
      type = types.str;
      default = "${config.users.users.${config.home.username}.gid}";
      description = "Group owner, it is recommended to get the group name from `config.users.users.<?name>.group` to avoid misconfiguration ";
    };

    ssh-config = mkOption {
      type = types.str;
      # default = "${config.home.homeDirectory}/.ssh/config";
      default = "/home/${config.home.username}/.ssh/config";
      description = "Where to store ssh config file";
    };

    yaml-config = mkOption {
      type = types.path;
      default = ./ssh.yaml;
      description = "Input Yaml file which will be converted into ssh config file";
    };

    age-keyfile = mkOption {
      type = types.string;
#      default = "${config.home.homeDirectory}/.sops/age.key";
      default = "/home/${config.home.username}/.sops/age.txt";
      description = "File which contains Age private keys";
    };
  };

  config = mkIf cfg.enable {
    home.activation.shoji =
      ''
        export SOPS_AGE_KEY_FILE=${cfg.age-keyfile}
        ${pkgs.sops}/bin/sops exec-file ${cfg.yaml-config} '${goProgram}/bin/shoji convert yaml -k ${cfg.ssh-folder} -o ${cfg.ssh-config} {}' && chown -R ${cfg.owner}:${cfg.group} ${cfg.ssh-folder} && chown ${cfg.owner}:${cfg.group} ${cfg.ssh-config}
      '';
  };
}

