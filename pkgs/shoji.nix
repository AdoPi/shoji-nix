{
  lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "shoji";
  name = "shoji";
  version = "0.0.3";

  src = fetchFromGitHub {
    owner = "AdoPi";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-uvpMGk0MbjR7kGRL2K1uP1vH30TAuz/ULEjObW6udyA=";
  };

  vendorHash = "sha256-vylraBVsuGFEFgd3GfKVWiMh2yQ2SYYURNidAJKSaus=";

  meta = with lib; {
    description = "SSH Key Management Module";
    homepage = "https://github.com/AdoPi/shoji";
    license = licenses.gpl3;
    maintainers = [ { name = "AdoPi"; email = "adopi.naj@gmail.com"; github = "AdoPi"; } ];
  };
}
