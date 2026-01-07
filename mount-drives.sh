#!/usr/bin/env bash
# MBO Server Configs - Linux Network Drive Setup
#
# Mounts:
#   //RBO-S1/s1_data  -> /mnt/s1_data
#   //RBO-S1/mbospace -> /mnt/mbospace
#
# Usage:
#   sudo ./mount-drives.sh           # Install and configure mounts
#   sudo ./mount-drives.sh mount     # Mount drives
#   sudo ./mount-drives.sh unmount   # Unmount drives
#   ./mount-drives.sh status         # Check mount status

set -e

# config
SERVER="RBO-S1"
SHARES=("s1_data" "mbospace")
MOUNT_BASE="/mnt"

# colors
info() { echo -e "\033[34m[INFO]\033[0m $*"; }
ok() { echo -e "\033[32m[OK]\033[0m $*"; }
warn() { echo -e "\033[33m[WARN]\033[0m $*"; }
err() { echo -e "\033[31m[ERROR]\033[0m $*"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        err "This script must be run with sudo"
        exit 1
    fi
}

get_real_user() {
    echo "${SUDO_USER:-$USER}"
}

get_real_home() {
    getent passwd "$(get_real_user)" | cut -d: -f6
}

get_creds_file() {
    echo "$(get_real_home)/.smbcredentials"
}

install_dependencies() {
    info "Checking dependencies..."

    if command -v apt-get &>/dev/null; then
        if ! dpkg -l cifs-utils &>/dev/null 2>&1; then
            info "Installing cifs-utils..."
            apt-get update -qq
            apt-get install -y cifs-utils
        fi
    elif command -v dnf &>/dev/null; then
        if ! rpm -q cifs-utils &>/dev/null 2>&1; then
            info "Installing cifs-utils..."
            dnf install -y cifs-utils
        fi
    elif command -v pacman &>/dev/null; then
        if ! pacman -Q cifs-utils &>/dev/null 2>&1; then
            info "Installing cifs-utils..."
            pacman -S --noconfirm cifs-utils
        fi
    else
        warn "Unknown package manager. Please install cifs-utils manually."
    fi

    ok "Dependencies ready"
}

setup_credentials() {
    local creds_file
    creds_file=$(get_creds_file)

    if [[ -f "$creds_file" ]]; then
        ok "Credentials file exists: $creds_file"
        return
    fi

    info "Setting up credentials for //$SERVER"
    echo ""

    read -p "  Username (domain\\user or user@domain): " smb_user
    read -sp "  Password: " smb_pass
    echo ""

    # create credentials file
    cat > "$creds_file" <<EOF
username=$smb_user
password=$smb_pass
EOF

    # secure permissions (readable only by owner)
    chown "$(get_real_user):$(get_real_user)" "$creds_file"
    chmod 600 "$creds_file"

    ok "Credentials saved to $creds_file (chmod 600)"
}

create_mount_points() {
    info "Creating mount points..."

    for share in "${SHARES[@]}"; do
        local mount_point="$MOUNT_BASE/$share"
        if [[ ! -d "$mount_point" ]]; then
            mkdir -p "$mount_point"
            ok "Created $mount_point"
        else
            ok "$mount_point exists"
        fi
    done
}

setup_fstab() {
    info "Configuring /etc/fstab..."

    local creds_file
    creds_file=$(get_creds_file)
    local uid
    uid=$(id -u "$(get_real_user)")
    local gid
    gid=$(id -g "$(get_real_user)")

    # backup fstab
    if [[ ! -f /etc/fstab.bak.mbo ]]; then
        cp /etc/fstab /etc/fstab.bak.mbo
        ok "Backed up /etc/fstab to /etc/fstab.bak.mbo"
    fi

    for share in "${SHARES[@]}"; do
        local mount_point="$MOUNT_BASE/$share"
        local share_path="//$SERVER/$share"
        local fstab_entry="$share_path $mount_point cifs credentials=$creds_file,uid=$uid,gid=$gid,file_mode=0644,dir_mode=0755,noauto,user,_netdev 0 0"

        # check if already in fstab
        if grep -q "$share_path" /etc/fstab; then
            ok "$share already in fstab"
        else
            echo "$fstab_entry" >> /etc/fstab
            ok "Added $share to fstab"
        fi
    done

    # reload systemd to pick up fstab changes
    systemctl daemon-reload 2>/dev/null || true
}

do_mount() {
    info "Mounting network drives..."

    for share in "${SHARES[@]}"; do
        local mount_point="$MOUNT_BASE/$share"

        if mountpoint -q "$mount_point" 2>/dev/null; then
            ok "$share already mounted"
        else
            if mount "$mount_point" 2>/dev/null; then
                ok "Mounted $share"
            else
                warn "Failed to mount $share (network unavailable?)"
            fi
        fi
    done
}

do_unmount() {
    info "Unmounting network drives..."

    for share in "${SHARES[@]}"; do
        local mount_point="$MOUNT_BASE/$share"

        if mountpoint -q "$mount_point" 2>/dev/null; then
            if umount "$mount_point"; then
                ok "Unmounted $share"
            else
                warn "Failed to unmount $share (in use?)"
            fi
        else
            ok "$share not mounted"
        fi
    done
}

show_status() {
    echo ""
    echo "  Network Drive Status"
    echo "  ====================="
    echo ""

    for share in "${SHARES[@]}"; do
        local mount_point="$MOUNT_BASE/$share"
        local share_path="//$SERVER/$share"

        if mountpoint -q "$mount_point" 2>/dev/null; then
            echo -e "  \033[32m●\033[0m $share_path -> $mount_point (mounted)"
        else
            echo -e "  \033[31m○\033[0m $share_path -> $mount_point (not mounted)"
        fi
    done

    echo ""
    echo "  Commands:"
    echo "    mount /mnt/s1_data     # Mount single drive"
    echo "    mount /mnt/mbospace"
    echo "    sudo $0 mount          # Mount all"
    echo "    sudo $0 unmount        # Unmount all"
    echo ""
}

do_install() {
    check_root
    install_dependencies
    setup_credentials
    create_mount_points
    setup_fstab

    echo ""
    ok "Setup complete!"
    echo ""
    echo "  To mount drives:"
    echo "    mount /mnt/s1_data"
    echo "    mount /mnt/mbospace"
    echo ""
    echo "  Or mount all at once:"
    echo "    sudo $0 mount"
    echo ""
}

# main
case "${1:-install}" in
    install)
        do_install
        ;;
    mount)
        check_root
        do_mount
        ;;
    unmount|umount)
        check_root
        do_unmount
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {install|mount|unmount|status}"
        exit 1
        ;;
esac
