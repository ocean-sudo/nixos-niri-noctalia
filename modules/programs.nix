{ config, pkgs, ... }:

{
# Install firefox.
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    starship
    kitty
    fastfetch
    helix
    btop
    cmatrix
    obsidian
    yazi
    bat
    lsd
   # obs-studio
    wireguard-tools
 ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
