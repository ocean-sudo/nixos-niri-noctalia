{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.dms.nixosModules.default
  ];

  programs.dms-shell = {
    enable = true;
    
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;
    
    systemd.enable = false;

    enableSystemMonitoring = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableVPN = true;
  };
  environment.systemPackages = [
    inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
