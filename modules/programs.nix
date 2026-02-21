{ config, pkgs, lib, inputs, ... }:

let
  zenBrowser = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default;
  browserLauncher = pkgs.writeShellScriptBin "browser" ''
    for browser in zen-beta zen zen-browser qutebrowser; do
      if command -v "$browser" >/dev/null 2>&1; then
        exec "$browser" "$@"
      fi
    done
    echo "No supported browser found (zen/qutebrowser)." >&2
    exit 1
  '';
in
{
  programs.firefox.enable = lib.mkForce false;
  environment.sessionVariables.BROWSER = "browser";

  xdg.mime = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "zen-beta.desktop" "qutebrowser.desktop" ];
      "x-scheme-handler/http" = [ "zen-beta.desktop" "qutebrowser.desktop" ];
      "x-scheme-handler/https" = [ "zen-beta.desktop" "qutebrowser.desktop" ];
    };
  };

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
    opencode
    wireguard-tools
    qutebrowser
  ] ++ [
    zenBrowser
    browserLauncher
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
