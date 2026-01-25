#!/usr/bin/env bash
set -euo pipefail

DIALOG=${DIALOG:-dialog}
BACKTITLE="nixpille NixOS Installer"
REPO_URL="github:cjavad/nixpille"

# Load cache configuration from shared module
if [[ -f /etc/nixpille/cache.env ]]; then
  # shellcheck source=/dev/null
  source /etc/nixpille/cache.env
else
  # Fallback
  NIX_FLAGS=""
fi

# Helper functions
die() {
  $DIALOG --backtitle "$BACKTITLE" --msgbox "Error: $1" 8 50
  exit 1
}

info() {
  $DIALOG --backtitle "$BACKTITLE" --infobox "$1" 5 50
  sleep 1
}

# Detect GPU type
detect_gpu() {
  local gpu_info
  gpu_info=$(lspci 2>/dev/null | grep -iE "vga|3d|display" || true)

  local has_nvidia=false has_amd=false has_intel=false
  [[ "$gpu_info" =~ [Nn][Vv][Ii][Dd][Ii][Aa] ]] && has_nvidia=true
  [[ "$gpu_info" =~ [Aa][Mm][Dd]|[Rr]adeon ]] && has_amd=true
  [[ "$gpu_info" =~ [Ii]ntel ]] && has_intel=true

  if $has_nvidia && $has_intel; then echo "intel-nvidia"
  elif $has_nvidia && $has_amd; then echo "amd-nvidia"
  elif $has_nvidia; then echo "nvidia"
  elif $has_amd; then echo "amd"
  elif $has_intel; then echo "intel"
  else echo "unknown"
  fi
}

# Show hardware summary
show_hardware_summary() {
  local cpu gpu mem disk gpu_type
  cpu=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "Unknown")
  gpu=$(lspci 2>/dev/null | grep -iE "vga|3d|display" | cut -d: -f3 | head -2 | xargs || echo "Unknown")
  gpu_type=$(detect_gpu)
  mem=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}' || echo "Unknown")
  disk=$(lsblk -d -n -o NAME,SIZE,MODEL 2>/dev/null | grep -v loop | head -3 || echo "Unknown")

  $DIALOG --backtitle "$BACKTITLE" \
    --title "Hardware Detected" \
    --msgbox "CPU: $cpu\n\nGPU: $gpu\nType: $gpu_type\n\nMemory: $mem\n\nDisks:\n$disk" 16 70
}

# Main menu
main_menu() {
  $DIALOG --backtitle "$BACKTITLE" \
    --title "Welcome" \
    --menu "What would you like to do?" 15 60 4 \
    "install"  "Install NixOS to disk" \
    "hardware" "Generate hardware.nix for a host" \
    "info"     "Show hardware information" \
    "shell"    "Exit to shell" \
    3>&1 1>&2 2>&3
}

# Disk selection
select_disk() {
  mapfile -t DISK_LINES < <(lsblk -d -n -p -o NAME,SIZE,MODEL | grep -v loop)
  DISK_MENU=()
  for line in "${DISK_LINES[@]}"; do
    disk=$(echo "$line" | awk '{print $1}')
    diskinfo=$(echo "$line" | awk '{$1=""; print substr($0,2)}')
    DISK_MENU+=("$disk" "$diskinfo")
  done

  [[ ${#DISK_MENU[@]} -eq 0 ]] && die "No disks found"

  $DIALOG --backtitle "$BACKTITLE" \
    --title "Select Disk" \
    --menu "Choose the target disk (WILL BE ERASED):" 15 60 5 \
    "${DISK_MENU[@]}" 3>&1 1>&2 2>&3
}

# Host selection
select_host() {
  $DIALOG --backtitle "$BACKTITLE" \
    --title "Select Host" \
    --menu "Choose host configuration:" 16 65 6 \
    "vm"      "Virtual machine (QEMU)" \
    "ideapad" "Lenovo IdeaPad (AMD+NVIDIA)" \
    "p1gen8"  "ThinkPad P1 Gen 8 (Intel+NVIDIA)" \
    "new"     "Create new host from this hardware" \
    3>&1 1>&2 2>&3
}

# Password input
get_password() {
  local username="$1"
  while true; do
    local pass1 pass2
    pass1=$($DIALOG --backtitle "$BACKTITLE" --title "Password" \
      --insecure --passwordbox "Enter password for $username:" 8 50 3>&1 1>&2 2>&3) || return 1
    pass2=$($DIALOG --backtitle "$BACKTITLE" --title "Confirm Password" \
      --insecure --passwordbox "Confirm password:" 8 50 3>&1 1>&2 2>&3) || return 1
    [[ "$pass1" == "$pass2" ]] && { echo "$pass1"; return 0; }
    $DIALOG --backtitle "$BACKTITLE" --msgbox "Passwords do not match." 6 40
  done
}

# Generate hardware.nix only (for existing or new host)
hardware_mode() {
  show_hardware_summary

  local hostname
  hostname=$($DIALOG --backtitle "$BACKTITLE" \
    --title "Host Name" \
    --inputbox "Enter hostname (existing or new):\n\nExisting hosts: vm, ideapad, p1gen8" 12 50 \
    "$(cat /sys/class/dmi/id/product_name 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]' || echo "new-host")" \
    3>&1 1>&2 2>&3) || return 1

  local output_dir="/tmp/nixpille-hosts/$hostname"
  mkdir -p "$output_dir"

  info "Generating hardware.nix..."
  nixos-generate-config --show-hardware-config > "$output_dir/hardware.nix" 2>/dev/null

  # Check if this is a new host (needs default.nix too)
  local is_new=true
  for existing in vm ideapad p1gen8 gha; do
    [[ "$hostname" == "$existing" ]] && is_new=false
  done

  if $is_new; then
    # Generate minimal default.nix for new host
    cat > "$output_dir/default.nix" << EOF
# Host: $hostname
# Generated: $(date -Iseconds)
{ config, pkgs, ... }:

{
  imports = [ ./hardware.nix ];
  networking.hostName = "$hostname";
  services.openssh.enable = true;
  system.stateVersion = "25.11";
}
EOF
    $DIALOG --backtitle "$BACKTITLE" \
      --title "New Host Generated" \
      --msgbox "Created new host config:\n\n  $output_dir/\n    ├── default.nix\n    └── hardware.nix\n\nCopy to hosts/$hostname/ in your repo.\nFlake auto-discovers new hosts!" 14 55
  else
    $DIALOG --backtitle "$BACKTITLE" \
      --title "Hardware Config Generated" \
      --msgbox "Generated hardware.nix for existing host '$hostname':\n\n  $output_dir/hardware.nix\n\nCopy to hosts/$hostname/hardware.nix" 12 55
  fi

  # Offer to view
  if $DIALOG --backtitle "$BACKTITLE" --yesno "View hardware.nix?" 7 30; then
    $DIALOG --backtitle "$BACKTITLE" --textbox "$output_dir/hardware.nix" 22 78
  fi

  # Offer to copy to USB
  local usb_mounts
  usb_mounts=$(lsblk -n -o MOUNTPOINT | grep -E "^/run/media|^/media" | head -5 || true)
  if [[ -n "$usb_mounts" ]]; then
    if $DIALOG --backtitle "$BACKTITLE" --yesno "Copy to USB?" 7 30; then
      local usb_menu=()
      while IFS= read -r mount; do
        [[ -n "$mount" ]] && usb_menu+=("$mount" "$(basename "$mount")")
      done <<< "$usb_mounts"

      if [[ ${#usb_menu[@]} -gt 0 ]]; then
        local usb_dest
        usb_dest=$($DIALOG --backtitle "$BACKTITLE" --menu "Copy to:" 12 60 5 \
          "${usb_menu[@]}" 3>&1 1>&2 2>&3) || return 0
        cp -r "$output_dir" "$usb_dest/"
        $DIALOG --backtitle "$BACKTITLE" --msgbox "Copied to: $usb_dest/$hostname/" 7 50
      fi
    fi
  fi
}

# Full installation
install_mode() {
  local device hostname username password

  # 1. Select disk
  device=$(select_disk) || return 1
  [[ -b "$device" ]] || die "$device is not a valid block device"

  # 2. Select host
  hostname=$(select_host) || return 1
  username="javad"

  if [[ "$hostname" == "new" ]]; then
    hostname=$($DIALOG --backtitle "$BACKTITLE" --title "Host Name" \
      --inputbox "Enter hostname for new machine:" 8 50 \
      "$(cat /sys/class/dmi/id/product_name 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]' || echo "new-host")" \
      3>&1 1>&2 2>&3) || return 1
  fi

  # 3. Password
  password=$(get_password "$username") || return 1

  # 4. Confirm
  $DIALOG --backtitle "$BACKTITLE" --title "Confirm" \
    --yesno "Install NixOS:\n\n  Disk: $device (WILL BE ERASED)\n  Host: $hostname\n  User: $username\n\nProceed?" 12 50 || return 0

  # 5. Partition
  info "Partitioning $device..."
  sudo nix run github:nix-community/disko -- \
    --mode disko \
    --arg device "\"$device\"" \
    /etc/nixpille/disko/standard.nix

  # 6. Generate hardware.nix
  info "Generating hardware config..."
  sudo mkdir -p /mnt/etc/nixpille/hosts/$hostname
  sudo nixos-generate-config --root /mnt --show-hardware-config > /tmp/hardware.nix
  sudo cp /tmp/hardware.nix /mnt/etc/nixpille/hosts/$hostname/

  # 7. Install
  info "Installing NixOS..."

  # Check if host exists in repo, otherwise use vm as base
  if nix eval --raw "$REPO_URL#nixosConfigurations.$hostname" 2>/dev/null; then
    sudo nixos-install --flake "$REPO_URL#$hostname" --no-root-passwd
  else
    $DIALOG --backtitle "$BACKTITLE" --msgbox \
      "Host '$hostname' not in repo yet.\n\nInstalling with 'vm' base.\nAfter boot, add hosts/$hostname/ to repo and rebuild." 10 55
    sudo nixos-install --flake "$REPO_URL#vm" --no-root-passwd
  fi

  # 8. Set password
  sudo nixos-enter --root /mnt -c "echo '$username:$password' | chpasswd"

  # 9. Done
  $DIALOG --backtitle "$BACKTITLE" --title "Complete" \
    --msgbox "NixOS installed!\n\nHardware config: /etc/nixpille/hosts/$hostname/\n\nRemove install media and reboot." 10 55
}

# Main
main() {
  while true; do
    local choice
    choice=$(main_menu) || exit 0

    case "$choice" in
      install) install_mode; break ;;
      hardware) hardware_mode ;;
      info) show_hardware_summary ;;
      shell) clear; echo "Run 'nixpille-install' to restart."; exit 0 ;;
    esac
  done

  clear
  echo "Done! Reboot to start your new system."
}

main "$@"
