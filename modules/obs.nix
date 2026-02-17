{ config, pkgs, ... }:

{
  # 1. 核心修复：通过覆盖属性 (Override) 强制注入库路径
  nixpkgs.config.packageOverrides = prev: {
    obs-studio = prev.obs-studio.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
      postInstall = (old.postInstall or "") + ''
        wrapProgram $out/bin/obs \
          --prefix LD_LIBRARY_PATH : "/run/opengl-driver/lib:/run/opengl-driver-32/lib" \
          --set OBS_USE_EGL 1
      '';
    });
  };

  # 2. 安装软件包
  environment.systemPackages = with pkgs; [
    obs-studio # 现在这个包已经被上面的覆盖逻辑注入了路径
    obs-studio-plugins.obs-vaapi
    obs-studio-plugins.obs-pipewire-audio-capture
  ];

  # 3. 确保硬件加速基础库存在
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  # 4. 设置会话变量
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
