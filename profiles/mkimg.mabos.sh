profile_mabos() {
    profile_standard
    title="MabOs"
    desc="MabOs Oasis: Alpine, OpenRC y MATE. Live experimental."
    arch="x86_64"
    image_name="mabos"
    profile_abbrev="mabos"
    hostname="mabos"
    kernel_addons=""
    boot_addons="amd-ucode intel-ucode"
    initrd_ucode="/boot/amd-ucode.img /boot/intel-ucode.img"
    # Los controladores gráficos y su firmware siguen en modloop. Udev los
    # carga antes de LightDM; no necesitan inflar el arranque inicial (KMS).
    # La ISO contiene un repositorio completo para arrancar sin Internet.
    apks="$(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$MABOS_INPUTS/config/packages.txt")"
    apkovl="${MABOS_INPUTS#/work/}/profiles/genapkovl-mabos.sh"
    syslinux_timeout=50
    syslinux_prompt=0
    kernel_cmdline="hostname=mabos rootflags=size=75%"
}

syslinux_gen_config() {
    cat <<EOF
TIMEOUT 30
PROMPT 1
DEFAULT mabos
SAY MabOs ${MABOS_VERSION} - Oasis
SAY Enter: iniciar MabOs. Escribe diagnostico para ver detalles del arranque.

LABEL mabos
    KERNEL /boot/vmlinuz-lts
    INITRD /boot/amd-ucode.img,/boot/intel-ucode.img,/boot/initramfs-lts
    APPEND $initfs_cmdline $kernel_cmdline

LABEL diagnostico
    KERNEL /boot/vmlinuz-lts
    INITRD /boot/amd-ucode.img,/boot/intel-ucode.img,/boot/initramfs-lts
    APPEND ${initfs_cmdline% quiet} $kernel_cmdline debug_init loglevel=7
EOF
}

grub_gen_config() {
    cat <<EOF
set timeout=3
set default=0
menuentry "Iniciar MabOs ${MABOS_VERSION} - Oasis" {
    linux /boot/vmlinuz-lts $initfs_cmdline $kernel_cmdline
    initrd /boot/amd-ucode.img /boot/intel-ucode.img /boot/initramfs-lts
}
menuentry "MabOs - diagnostico de arranque" {
    linux /boot/vmlinuz-lts ${initfs_cmdline% quiet} $kernel_cmdline debug_init loglevel=7
    initrd /boot/amd-ucode.img /boot/intel-ucode.img /boot/initramfs-lts
}
EOF
}
