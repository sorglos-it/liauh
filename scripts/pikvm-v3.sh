#!/bin/bash

# PiKVM v3 Certificate Management Script
# Install and manage SSL certificates via Step-CA for PiKVM v3 (Arch Linux)

set -e

FULL_PARAMS="$1"
ACTION="${FULL_PARAMS%%,*}"
PARAMS_REST="${FULL_PARAMS#*,}"

if [[ -n "$PARAMS_REST" && "$PARAMS_REST" != "$FULL_PARAMS" ]]; then
    while IFS='=' read -r key val; do
        [[ -n "$key" ]] && export "$key=$val"
    done <<< "${PARAMS_REST//,/$'\n'}"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

log_error() {
    printf "${RED}✗${NC} %s\n" "$1"
    exit 1
}

update_pikvm() {
    log_info "Updating PiKVM v3..."
    
    log_info "Step 1: Switching to read-write mode..."
    sudo rw || log_error "Failed to switch to read-write mode"
    
    log_info "Step 2: Running pikvm-update..."
    sudo pikvm-update || log_error "Failed to update PiKVM"
    
    log_info "Step 3: Switching back to read-only mode..."
    sudo ro || log_error "Failed to switch to read-only mode"
    
    log_info "Step 4: Rebooting system..."
    log_warn "System will reboot in 5 seconds..."
    sleep 5
    sudo reboot || log_error "Failed to reboot"
}

mount_iso() {
    log_info "Mounting ISO directory..."
    
    log_info "Step 1: Switching to read-write mode..."
    sudo rw || log_error "Failed to switch to read-write mode"
    
    log_info "Step 2: Remounting ISO directory in read-write mode..."
    sudo kvmd-helper-otgmsd-remount rw || log_error "Failed to remount ISO directory"
    
    log_info "Step 3: Creating symlink in /home..."
    sudo mkdir -p /home || log_warn "Could not create /home directory"
    sudo ln -sf /var/lib/kvmd/msd/ /home/isodir || log_error "Failed to create symlink"
    
    log_info "Step 4: Switching back to read-only mode..."
    sudo ro || log_error "Failed to switch to read-only mode"
    
    log_info "ISO directory mounted successfully!"
    log_info "Access ISO directory at: /home/isodir"
}

dismount_iso() {
    log_info "Dismounting ISO directory..."
    
    log_info "Step 1: Remounting ISO directory in read-only mode..."
    sudo kvmd-helper-otgmsd-remount ro || log_error "Failed to remount ISO directory"
    
    log_info "ISO directory dismounted successfully!"
    log_info "Symlink /home/isodir remains for future use"
}

enable_oled() {
    log_info "Enabling OLED display..."
    
    log_info "Step 1: Switching to read-write mode..."
    sudo rw || log_error "Failed to switch to read-write mode"
    
    log_info "Step 2: Enabling kvmd-oled service..."
    sudo systemctl enable --now kvmd-oled || log_error "Failed to enable kvmd-oled"
    
    log_info "Step 3: Switching back to read-only mode..."
    sudo ro || log_error "Failed to switch to read-only mode"
    
    log_info "OLED display enabled successfully!"
}

vnc_enable() {
    log_info "Enabling VNC..."
    
    log_info "Step 1: Switching to read-write mode..."
    sudo rw || log_error "Failed to switch to read-write mode"
    
    log_info "Step 2: Configuring VNC..."
    echo "vnc:" | sudo tee -a /etc/kvmd/override.yaml >/dev/null || log_error "Failed to write config"
    echo "    keymap: /usr/share/kvmd/keymaps/de" | sudo tee -a /etc/kvmd/override.yaml >/dev/null || log_error "Failed to write config"
    echo "    auth:" | sudo tee -a /etc/kvmd/override.yaml >/dev/null || log_error "Failed to write config"
    echo "        vncauth:" | sudo tee -a /etc/kvmd/override.yaml >/dev/null || log_error "Failed to write config"
    echo "            enabled: true" | sudo tee -a /etc/kvmd/override.yaml >/dev/null || log_error "Failed to write config"
    
    log_info "Step 3: Enabling kvmd-vnc service..."
    sudo systemctl enable --now kvmd-vnc || log_error "Failed to enable kvmd-vnc"
    
    log_info "Step 4: Switching back to read-only mode..."
    sudo ro || log_error "Failed to switch to read-only mode"
    
    log_info "VNC enabled successfully!"
    log_info "Configuration saved in /etc/kvmd/override.yaml"
}

vnc_user() {
    log_info "Setting VNC user..."
    
    [[ -z "$VNC_USERNAME" ]] && log_error "VNC_USERNAME not set"
    [[ -z "$VNC_PASSWORD" ]] && log_error "VNC_PASSWORD not set"
    
    log_info "Step 1: Switching to read-write mode..."
    sudo rw || log_error "Failed to switch to read-write mode"
    
    log_info "Step 2: Writing VNC user credentials..."
    echo "$VNC_USERNAME -> $VNC_USERNAME:$VNC_PASSWORD" | sudo tee /etc/kvmd/vncpasswd >/dev/null || log_error "Failed to write VNC credentials"
    
    log_info "Step 3: Restarting kvmd-vnc service..."
    sudo systemctl restart kvmd-vnc || log_error "Failed to restart kvmd-vnc"
    
    log_info "Step 4: Switching back to read-only mode..."
    sudo ro || log_error "Failed to switch to read-only mode"
    
    log_info "VNC user configured successfully!"
    log_info "Username: $VNC_USERNAME"
}

rtc_enable() {
    log_info "Enabling RTC (Geekworm)..."
    
    log_info "Step 1: Switching to read-write mode..."
    sudo rw || log_error "Failed to switch to read-write mode"
    
    log_info "Step 2: Configuring RTC in /boot/config.txt..."
    sudo sed -i 's/pcf8563/ds1307/g' /boot/config.txt || log_error "Failed to update config.txt"
    
    log_info "Step 3: Checking system date..."
    sudo date || log_warn "Failed to check date"
    
    log_info "Step 4: Writing system time to RTC..."
    sudo hwclock -w || log_error "Failed to write to RTC"
    
    log_info "Step 5: Reading RTC..."
    sudo hwclock -r || log_warn "Failed to read RTC"
    
    log_info "Step 6: Switching back to read-only mode..."
    sudo ro || log_error "Failed to switch to read-only mode"
    
    log_info "RTC configured successfully!"
    log_warn "Rebooting system to apply changes..."
    
    sleep 5
    sudo reboot || log_error "Failed to reboot"
}

atx_disable() {
    log_info "Disabling ATX menu..."
    
    log_info "Step 1: Switching to read-write mode..."
    sudo rw || log_error "Failed to switch to read-write mode"
    
    log_info "Step 2: Configuring ATX as disabled..."
    echo "kvmd:" | sudo tee -a /etc/kvmd/override.yaml >/dev/null || log_error "Failed to write config"
    echo "    atx: " | sudo tee -a /etc/kvmd/override.yaml >/dev/null || log_error "Failed to write config"
    echo "        type: disabled " | sudo tee -a /etc/kvmd/override.yaml >/dev/null || log_error "Failed to write config"
    
    log_info "Step 3: Switching back to read-only mode..."
    sudo ro || log_error "Failed to switch to read-only mode"
    
    log_info "ATX menu disabled successfully!"
    log_info "Configuration saved in /etc/kvmd/override.yaml"
}

create_usb_img() {
    log_info "Creating USB stick IMG..."
    
    [[ -z "$USB_SIZE_GB" ]] && log_error "USB_SIZE_GB not set"
    [[ -z "$USB_NAME" ]] && log_error "USB_NAME not set"
    
    # Calculate count: size in MB (since bs=1M)
    local count=$((USB_SIZE_GB * 1024))
    local img_path="/var/lib/kvmd/msd/$USB_NAME"
    
    log_info "Creating USB IMG: $USB_NAME ($USB_SIZE_GB GB)"
    
    log_info "Step 1: Switching to read-write mode..."
    sudo rw || log_error "Failed to switch to read-write mode"
    
    log_info "Step 2: Creating empty IMG file (this may take a while - please wait)..."
    log_warn "This operation may take 1-5 minutes depending on disk speed..."
    sudo dd if=/dev/zero of="$img_path" bs=1M count=$count status=progress 2>&1 || log_error "Failed to create IMG file"
    
    log_info "Step 3: Finding free loop device..."
    local loop=$(sudo losetup -f) || log_error "Failed to find free loop device"
    log_info "Using loop device: $loop"
    
    log_info "Step 4: Creating partition table..."
    echo -e 'o\nn\np\n1\n\n\nt\nc\nw\n' | sudo fdisk "$img_path" || log_error "Failed to create partition table"
    
    log_info "Step 5: Attaching loop device with partitions..."
    sudo losetup -P "$loop" "$img_path" || log_error "Failed to attach loop device"
    
    log_info "Step 6: Formatting partition as FAT32..."
    sudo mkfs.vfat "${loop}p1" || log_error "Failed to format partition"
    
    log_info "Step 7: Detaching loop device..."
    sudo losetup -d "$loop" || log_error "Failed to detach loop device"
    
    log_info "Step 8: Setting permissions..."
    sudo chmod 666 "$img_path" || log_error "Failed to set permissions"
    
    log_info "Step 9: Switching back to read-only mode..."
    sudo ro || log_error "Failed to switch to read-only mode"
    
    log_info "USB IMG created successfully!"
    log_info "IMG file: $img_path"
    log_info "Size: $USB_SIZE_GB GB"
}

change_hostname() {
    log_info "Changing PiKVM hostname..."
    
    [[ -z "$HOSTNAME" ]] && log_error "HOSTNAME not set"
    
    log_info "Step 1: Switching to read-write mode..."
    sudo rw || log_error "Failed to switch to read-write mode"
    
    log_info "Step 2: Setting new hostname: $HOSTNAME..."
    sudo hostnamectl set-hostname "$HOSTNAME" || log_error "Failed to set hostname"
    
    log_info "Step 3: Configuring kvmd metadata..."
    echo "server:" | sudo tee /etc/kvmd/meta.yaml >/dev/null || log_error "Failed to write meta.yaml"
    echo "    host: $HOSTNAME" | sudo tee -a /etc/kvmd/meta.yaml >/dev/null || log_error "Failed to write meta.yaml"
    echo "" | sudo tee -a /etc/kvmd/meta.yaml >/dev/null || log_error "Failed to write meta.yaml"
    echo "kvm: {}" | sudo tee -a /etc/kvmd/meta.yaml >/dev/null || log_error "Failed to write meta.yaml"
    
    log_info "Step 4: Switching back to read-only mode..."
    sudo ro || log_error "Failed to switch to read-only mode"
    
    log_info "Step 5: Rebooting system to apply changes..."
    log_warn "System will reboot in 5 seconds..."
    sleep 5
    sudo reboot || log_error "Failed to reboot"
}

setup_ca_certificate() {
    log_info "Setting up CA certificate from Step-CA..."
    
    [[ -z "$CA_SERVER" ]] && log_error "CA_SERVER not set"
    [[ -z "$ACME_SERVER" ]] && log_error "ACME_SERVER not set"
    [[ -z "$PIKVM_DOMAIN" ]] && log_error "PIKVM_DOMAIN not set"
    
    log_info "Step 1: Switching to read-write mode..."
    sudo rw || log_warn "Could not switch to read-write mode"
    
    log_info "Step 2: Downloading CA certificate from $CA_SERVER..."
    echo | openssl s_client -connect "$CA_SERVER:443" -showcerts 2>/dev/null | openssl x509 -outform PEM > /tmp/ca.crt || log_error "Failed to download CA certificate"
    
    log_info "Step 3: Installing CA certificate..."
    sudo mkdir -p /usr/local/share/ca-certificates/ || log_warn "Directory already exists"
    sudo cp /tmp/ca.crt /usr/local/share/ca-certificates/ || log_error "Failed to copy CA certificate"
    sudo cat /tmp/ca.crt >> /etc/ssl/certs/ca-certificates.crt || log_error "Failed to append CA certificate"
    
    log_info "Step 4: Verifying kvmd service..."
    if ! command -v kvmd-pstrun &>/dev/null; then
        log_error "kvmd-pstrun not found - this must be run on PiKVM v3"
    fi
    
    sudo kvmd-pstrun -- true || log_error "Failed to verify kvmd service"
    
    log_info "Step 5: Requesting certificate from Step-CA..."
    sudo kvmd-certbot certonly_webroot --agree-tos -n -d "$PIKVM_DOMAIN" --server "$ACME_SERVER" || log_error "Failed to request certificate"
    
    log_info "Step 6: Installing certificate for Nginx..."
    sudo kvmd-certbot install_nginx "$PIKVM_DOMAIN" || log_error "Failed to install Nginx certificate"
    
    log_info "Step 7: Installing certificate for VNC..."
    sudo kvmd-certbot install_vnc "$PIKVM_DOMAIN" || log_error "Failed to install VNC certificate"
    
    log_info "Step 8: Testing certificate renewal..."
    sudo kvmd-certbot renew --force-renewal || log_error "Failed to test certificate renewal"
    
    log_info "Step 9: Enabling automatic certificate renewal..."
    sudo systemctl enable --now kvmd-certbot.timer || log_error "Failed to enable kvmd-certbot timer"
    
    log_info "Step 10: Switching back to read-only mode..."
    sudo ro || log_warn "Could not switch back to read-only mode"
    
    log_info "PiKVM v3 certificate setup completed successfully!"
    log_info "Certificate for $PIKVM_DOMAIN installed"
    log_info "Auto-renewal enabled via kvmd-certbot.timer"
    log_warn "Rebooting system to apply changes..."
    
    sleep 3
    sudo reboot || log_error "Failed to reboot"
}

case "$ACTION" in
    update)
        update_pikvm
        ;;
    
    mount-iso)
        mount_iso
        ;;
    
    dismount-iso)
        dismount_iso
        ;;
    
    oled-enable)
        enable_oled
        ;;
    
    hostname)
        change_hostname
        ;;
    
    vnc-enable)
        vnc_enable
        ;;
    
    vnc-user)
        vnc_user
        ;;
    
    rtc-enable)
        rtc_enable
        ;;
    
    atx-disable)
        atx_disable
        ;;
    
    create-usb-img)
        create_usb_img
        ;;
    
    setup)
        setup_ca_certificate
        ;;
    
    *)
        log_error "Unknown action: $ACTION"
        echo "Usage:"
        echo "  pikvm-v3.sh update"
        echo "  pikvm-v3.sh mount-iso"
        echo "  pikvm-v3.sh dismount-iso"
        echo "  pikvm-v3.sh oled-enable"
        echo "  pikvm-v3.sh hostname,HOSTNAME=pikvm.my.lan"
        echo "  pikvm-v3.sh vnc-enable"
        echo "  pikvm-v3.sh vnc-user,VNC_USERNAME=admin,VNC_PASSWORD=password"
        echo "  pikvm-v3.sh rtc-enable"
        echo "  pikvm-v3.sh atx-disable"
        echo "  pikvm-v3.sh create-usb-img,USB_SIZE_GB=16,USB_NAME=usb_stick_16gb.img"
        echo "  pikvm-v3.sh setup,CA_SERVER=ca.my.lan,PIKVM_DOMAIN=pikvm.my.lan,ACME_SERVER=https://ca.my.lan/acme/acme/directory"
        exit 1
        ;;
esac
