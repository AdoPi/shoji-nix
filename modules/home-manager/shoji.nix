{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.home.shoji;
  primaryGroup = builtins.getEnv "GROUP";
  currentUser = builtins.getEnv "USER";
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
      default = if config.home.homeDirectory != null then "${config.home.homeDirectory}/.ssh/" else "~/.ssh/";
      description = "Keys directory";
    };

    owner = mkOption {
      type = types.str;
      default = "${currentUser}";
      description = "Owner, it is recommended to get the group name from `config.users.users.<?name>.name` to avoid misconfiguration ";
    };

    group = mkOption {
      type = types.str;
      default = "${primaryGroup}";
      description = "Group owner, it is recommended to get the group name from `config.users.users.<?name>.group` to avoid misconfiguration ";
    };

    ssh-config = mkOption {
      type = types.str;
      default = if config.home.homeDirectory != null then "${config.home.homeDirectory}/.ssh/config" else "~/.ssh/config";
      description = "Where to store ssh config file";
    };

    yaml-config = mkOption {
      type = types.path;
      description = "Input Yaml file which will be converted into ssh config file";
    };

    age-keyfile = mkOption {
      type = types.string;
      default = "";
      description = "File which contains Age private keys";
    };
  };

  config = mkIf config.home.shoji.enable {
    home.activation.shoji =  lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ -n "${cfg.age-keyfile}" ]; then
		export SOPS_AGE_KEY_FILE=${cfg.age-keyfile}
	fi
        ${pkgs.sops}/bin/sops exec-file ${cfg.yaml-config} '${goProgram}/bin/shoji convert yaml -k ${cfg.ssh-folder} -o ${cfg.ssh-config} {}' && chown -R ${cfg.owner}:${cfg.group} ${cfg.ssh-folder} && chown ${cfg.owner}:${cfg.group} ${cfg.ssh-config}
      '';
  };
}

