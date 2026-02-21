#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/ocean-sudo/nixos-niri-noctalia.git}"
REPO_BRANCH="${REPO_BRANCH:-master}"
TARGET_DIR="${TARGET_DIR:-/etc/nixos/nixos-niri-noctalia}"
FLAKE_HOST="${FLAKE_HOST:-nixos}"
SYNC_DOTFILES="${SYNC_DOTFILES:-0}"
TARGET_USER="${TARGET_USER:-${SUDO_USER:-}}"

log() {
  printf '[bootstrap] %s\n' "$*"
}

die() {
  printf '[bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

run_git() {
  if command -v git >/dev/null 2>&1; then
    git "$@"
    return
  fi

  if command -v nix-shell >/dev/null 2>&1; then
    # shellcheck disable=SC2145
    nix-shell -p git --run "git $*"
    return
  fi

  die "git 不存在，且 nix-shell 不可用，无法拉取仓库。"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "缺少命令: $1"
}

if [[ "$(id -u)" -ne 0 ]]; then
  die "请用 root 运行。示例: curl -fsSL <raw-url> | sudo bash"
fi

require_cmd nixos-rebuild
require_cmd nixos-generate-config
require_cmd getent

mkdir -p "$(dirname "$TARGET_DIR")"

if [[ -d "$TARGET_DIR/.git" ]]; then
  log "检测到现有仓库，尝试更新: $TARGET_DIR"
  run_git -C "$TARGET_DIR" fetch --all --prune
  if run_git -C "$TARGET_DIR" show-ref --verify --quiet "refs/heads/$REPO_BRANCH"; then
    run_git -C "$TARGET_DIR" checkout "$REPO_BRANCH"
  else
    run_git -C "$TARGET_DIR" checkout -b "$REPO_BRANCH" "origin/$REPO_BRANCH"
  fi
  run_git -C "$TARGET_DIR" pull --ff-only origin "$REPO_BRANCH"
elif [[ -e "$TARGET_DIR" ]]; then
  die "目标路径已存在且不是 git 仓库: $TARGET_DIR"
else
  log "克隆仓库到: $TARGET_DIR"
  run_git clone --branch "$REPO_BRANCH" "$REPO_URL" "$TARGET_DIR"
fi

if [[ -f "$TARGET_DIR/hardware-configuration.nix" ]]; then
  backup="$TARGET_DIR/hardware-configuration.nix.bak.$(date +%Y%m%d%H%M%S)"
  cp "$TARGET_DIR/hardware-configuration.nix" "$backup"
  log "已备份旧硬件配置: $backup"
fi

nixos-generate-config --show-hardware-config > "$TARGET_DIR/hardware-configuration.nix"
log "已生成本机 hardware-configuration.nix"

if [[ "$SYNC_DOTFILES" == "1" && -n "$TARGET_USER" ]]; then
  user_home="$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)"
  if [[ -z "$user_home" || ! -d "$user_home" ]]; then
    log "跳过 dotfiles 同步，未找到用户家目录: $TARGET_USER"
  else
    log "同步 dotfiles 到: $user_home"
    cp -a "$TARGET_DIR/dotfiles/." "$user_home/"
    user_group="$(id -gn "$TARGET_USER")"
    chown -R "$TARGET_USER:$user_group" "$user_home/.config" "$user_home/.bashrc" "$user_home/.inputrc" "$user_home/.vimrc" 2>/dev/null || true
  fi
else
  log "跳过 dotfiles 同步 (SYNC_DOTFILES=$SYNC_DOTFILES)"
fi

log "开始应用系统配置: $TARGET_DIR#$FLAKE_HOST"
nixos-rebuild switch --flake "$TARGET_DIR#$FLAKE_HOST"
log "完成。"
