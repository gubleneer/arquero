#!/bin/bash

# stuff
echo "Please check that you partitioned the disk first. If you didn't, this might cause loss of data!"
sleep 3

echo "Enter your ESP."
read ESP

echo "Enter your SWAP partition."
read SWAP

echo "Enter your Root partition."
read ROOT

echo "Enter your username."
read USER

echo "Enter the password for the newly created user."
read PASSWORD


echo "Choose your DE."
echo "1. GNOME"
echo "2. KDE Plasma"
echo "3. XFCE"
echo "4. Plain TTY."
read DESKTOP

echo -e "\nCreating and mounting the filesystems...\n"

mkfs.fat -F 32 -n "EFISP" "${ESP}"
mkswap "${SWAP}"
mkfs.ext4 -L "ROOT" "${ROOT}"

# mounting
mount "${ROOT}" /mnt
mkdir -p /mnt/boot/efi
mount "${ESP}" /mnt/boot/efi

echo "///////////////////////////////////////"
echo "/////// Installing Arch Linux.. //////"
echo "/////////////////////////////////////"
pacman-key --init

pacman-key --populate

# base stuff

pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr --noconfirm --needed 

echo "///////////////////////////////////"
echo "///////// Dependencies //////////"
echo "///////////////////////////////"
pacstrap -K /mnt networkmanager nm-applet vim intel-ucode --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "/////////////////////////////////"
echo "//////// systemd-boot //////////"
echo "///////////////////////////////"
bootctl install --path /mnt/boot/efi
echo "default arch.conf" >> /mnt/boot/efi/loader/loader.conf
cat <<EOF > /mnt/boot/efi/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root-${ROOT} rw
EOF


cat <<REALEND > /mnt/next.sh
useradd -m -G wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "///////////////////////////"
echo "////// lang setup ////////
echo "////////////////////////
sed -i 's/^#es_PE.UTF-8 UTF-8/es_PE.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=es_PE.UTF-8" >> /etc/locale.conf

ln -sf /usr/share/zoneinfo/America/Lima /etc/localtime
hwclock --systohc

echo "arquero" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	arquero.localdomain	arquero
EOF

echo "////////////////////////"
echo "/// display n audio ///
echo "//////////////////////

pacman -S xorg pipewire --noconfirm --needed

systemctl enable NetworkManager

#DESKTOP ENVIROMENT
if [[ $DESKTOP == '1' ]]
then
    pacman -S gnome gdm --noconfirm --needed
    systemctl enable gdm
elif [[ $DESKTOP == '2' ]]			
then
    pacman -S plasma sddm kde-applications
    systemctl enable sddm
elif [[ $DESKTOP == '3' ]]
then	
    pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter --noconfirm --needed
    systemctl enable lightdm
else
    echo "You have chosen to install the desktop, but you didnt; You are in this TTY."
fi

echo "//////////////////////
echo "/// COMPLETE ////////
echo "/// Reboot now. ////
echo "///////////////////

REALEND


arch-chroot /mnt sh next.sh
     	
