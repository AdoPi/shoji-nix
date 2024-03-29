{ config, buildGoModule, lib, pkgs, vendorHash, go, sops, pinentry, gnupg, age, gawk, sed, ... }:
with lib;

let
  cfg = config.shoji;
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
  options.shoji = {
    enable = mkEnableOption "shoji";

    ssh-folder = mkOption {
      type = types.str;
      default = "~/.ssh/";
      description = "Keys directory";
    };

    owner = mkOption {
      type = types.str;
      default = "1000";
      description = "Owner, it is recommended to get the group name from `config.users.users.<?name>.name` to avoid misconfiguration ";
    };

    group = mkOption {
      type = types.str;
      default = "";
      description = "Group owner, it is recommended to get the group name from `config.users.users.<?name>.group` to avoid misconfiguration ";
    };

    ssh-config = mkOption {
      type = types.str;
      default = "~/.ssh/config";
      description = "Where to store ssh config file";
    };

    yaml-config = mkOption {
      type = types.path;
      default = ./ssh.yaml;
      description = "Input Yaml file which will be converted into ssh config file";
    };
    age-keyfile = mkOption {
      type = types.string;
      default = "/root/.sops/age.key";
      description = "File which contains Age private keys";
    };
  };

# Note: Could be nice to add GPG support
  config = mkIf cfg.enable {
    system.activationScripts.shoji = {
      text = ''
	export SOPS_AGE_KEY_FILE=${cfg.age-keyfile} 
	${pkgs.sops}/bin/sops exec-file ${cfg.yaml-config} '${goProgram}/bin/shoji convert yaml -k ${cfg.ssh-folder} -o ${cfg.ssh-config} {}' && chown -R ${cfg.owner}:${cfg.group} ${cfg.ssh-folder} && chown ${cfg.owner}:${cfg.group} ${cfg.ssh-config}
      '';
    };
  };
}

