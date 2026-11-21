# Pruebas de MabOs 0.1

## Alpha3 — cambios solicitados comprobados en VM

- ISO: `dist/mabos-0.1.0-alpha3-x86_64.iso`.
- SHA-256: `0caa333843d0a9e16a4e232ebb35a490a0ba2efda94121f042c86663be3b7883`.
- Tamaño: 915 406 848 bytes (873 MiB).
- Integridad, estructura BIOS/UEFI y overlay comprobados; 643 paquetes.
- Comparación con alpha2: ningún paquete anterior eliminado o actualizado.
  Solo AbiWord y sus cinco dependencias, según el manifiesto.
- Fondo e initramfs idénticos a alpha2; ISO alpha1 y alpha2 conservadas.
- 18 pruebas automatizadas correctas.
- Controles y bordes YaruOk, iconos Papirus-Light y panel único superior
  confirmados mediante GSettings y capturas.
- Lista de ventanas funcional: Terminal, AbiWord y Firefox aparecen en el
  panel superior. Sin panel inferior.
- Logo de diente de león visible en el menú; logotipo MabOs incluido.
- AbiWord 3.0.8 abrió un documento y se escribieron dos líneas, confirmadas
  visualmente. No se probaron guardado, importación ni exportación de formatos.
- BIOS y UEFI arrancaron MATE. Ventoy 1.1.18, modo normal, UEFI y disco
  virtual MBR/FAT32 también llegó al escritorio.
- Firefox abrió Alpine por HTTPS y la red virtual funcionó.
- La primera captura UEFI se tomó mientras todavía aparecía un fondo negro;
  las capturas posteriores, BIOS y Ventoy muestran el fondo Oasis conservado.
- Evidencias: `logs/alpha3-uefi-abiword.png`, `logs/alpha3-uefi-apps.png`,
  `logs/alpha3-bios.png`, `logs/alpha3-ventoy-normal.png` y
  `logs/alpha3-uefi.serial.log`.
- El chequeo CLI de versión de AbiWord bajo doas produjo una advertencia de
  autorización gráfica; la prueba gráfica como usuario live sí funcionó.
- Sonido y Wi-Fi fueron confirmados por el usuario en alpha2, no en alpha3.
- Pendiente: arranque y comprobaciones específicas de alpha3 en hardware real.

## Alpha2 Oasis — lista para pruebas físicas experimentales

**Incidencia resuelta según el usuario:** inicialmente falló Ventoy en modo normal:
`invalid magic number` seguido de `you need to load the kernel first`.
Tras volver a copiar la misma ISO al USB, el usuario confirmó que funcionó
correctamente con Ventoy 1.1.18. No se modificó la imagen del proyecto.
No se dispone del checksum de la copia fallida para confirmar la causa exacta.

Prueba adicional: Ventoy **1.1.18**, modo normal, UEFI y disco virtual
MBR/FAT32 sí llegó a MATE. Evidencia revisada:
`logs/ventoy-alpha2-normal-full-timeout.png`.
El sufijo `timeout` es del detector de consola: no apareció el prompt serie
esperado, pero la captura muestra el escritorio iniciado. **No significa que
el arranque tardase 360 s**. La confirmación física posterior proviene del usuario.

- ISO: `dist/mabos-0.1.0-alpha2-x86_64.iso`.
- SHA-256: `abdaf93028f402710f1548715ab4803a50f7555a1eef6d0766368ebc2cc96cc2`.
- Tamaño: 907 018 240 bytes (865 MiB).
- Suma, BIOS/UEFI estructurales, overlay, versión y 637 paquetes comprobados.
- Initramfs: 22 542 320 bytes, frente a 179 926 528 bytes de alpha1.
- 12 pruebas automatizadas correctas.
- Fondo y cactus originales renderizados correctamente como vista previa.
- BIOS y UEFI correctos: sesión MATE automática, fondo Oasis, cactus en
  Aplicaciones e iconos Papirus visibles.
- Papirus y YaruGreen confirmados mediante GSettings del usuario.
- Bienvenida abierta y revisada visualmente, usando Cairo sin requerir 3D.
  No se probaron todos sus botones.
- Firefox abrió gráficamente `https://alpinelinux.org`; Ethernet, DNS y HTTPS
  comprobados. Servicios OpenRC activos; PulseAudio con salida nula virtual.
- Evidencias: `logs/oasis-release-uefi.png`, `logs/oasis-release-bios.png`,
  `logs/oasis-release-uefi-welcome.png`, `logs/oasis-release-uefi-apps.png`,
  `logs/oasis-release-uefi.serial.log`.
- Tiempo hasta getty: UEFI **86.34 s**, BIOS **60.48 s**, con KVM, 3072 MiB
  y dos CPU virtuales. No son tiempos exactos hasta escritorio ni cifras
  garantizadas para USB real; metodología y límites en `docs/ARRANQUE.md`.
- Arranque físico de alpha2 confirmado por el usuario tras recopiar la ISO.
  Wi-Fi, audio, gráficos, suspensión y apagado requieren comprobaciones específicas.

## Alpha1 — referencia anterior

ISO actual: `dist/mabos-0.1.0-alpha1-x86_64.iso`.

- Tamaño: 1 025 507 328 bytes (978 MiB).
- SHA-256: `ddfb3a08b747ff8d441da8ade665ded92cc6c3d166f8fb6ded577233a44a0d98`.
- Suma y estructura comprobadas con `scripts/check-iso.sh`.
- Entradas de arranque BIOS y UEFI presentes; MBR híbrido y GPT presentes.
- Overlay validado y 634 paquetes inventariados en `dist/packages.tsv`.
- Imagen actual: BIOS y UEFI **correctos**, entrada automática a MATE en
  español, con QEMU/KVM y 3072 MiB de RAM.
- Firefox ESR abrió gráficamente `https://alpinelinux.org`.
- Ethernet virtual, resolución DNS y HTTPS comprobados.
- OpenRC: dbus, elogind, preparación live, wpa_supplicant, NetworkManager,
  LightDM y Chrony activos.
- Hardware real: **pendiente**.

PulseAudio funcionó con salida nula por no haber tarjeta de audio virtual.
Esto no valida altavoces, auriculares ni reproducción audible.

### Evidencias de la imagen actual

- `logs/vm-bios.png`: escritorio tras arranque BIOS.
- `logs/vm-uefi.png`: escritorio tras arranque UEFI.
- `logs/vm-uefi-apps.png`: Firefox cargando la web de Alpine por HTTPS.
- `logs/vm-uefi.serial.log`: diagnóstico dentro de la sesión.
- `logs/iso-structure.txt`: estructura de arranque y extracción del overlay.

### Limitaciones conocidas y pruebas pendientes

- Firefox tiene interfaz en inglés en esta selección inicial; MATE está en español.
- Teclado inicial estadounidense, modificable desde las preferencias de MATE.
- El primer arranque instala el escritorio en RAM y puede tardar varios minutos.
- No se han probado Wi-Fi físico, audio audible, suspensión, batería ni GPU real.
- El servicio wpa_supplicant activo no demuestra compatibilidad con un adaptador Wi-Fi.
- Evince y Celluloid están incluidos, pero no se ha comprobado su uso gráfico
  ni una reproducción multimedia completa.
- El apagado y reinicio desde MATE todavía deben probarse. Las VM de esta
  validación se cerraron con QMP, no mediante el apagado del invitado.
- Las pruebas con CD virtual no sustituyen el arranque desde USB físico.

## Antes de probar

- Medio experimental: no usar datos importantes.
- Arquitectura x86_64, arranque BIOS o UEFI; Secure Boot no soportado.
- Recomendación provisional: 4 GiB de RAM o más. Pendiente de medir:
  Alpine instala el escritorio en RAM durante el arranque live.
- El primer arranque puede tardar mientras se cargan los paquetes.
- Sin persistencia: guardar los archivos en otro medio antes de apagar.
- Sin SSH. Usuario local `live` sin contraseña y `doas` sin contraseña.

## Máquina virtual

1. Conectar exclusivamente la ISO, sin discos reales ni directorios compartidos.
2. Probar BIOS y UEFI por separado.
3. Confirmar entrada automática a MATE.
4. Abrir terminal, archivos, navegador, PDF, calculadora y reproductor.
5. Comprobar red y resolución DNS.
6. Confirmar cierre de sesión, reinicio y apagado.
7. Guardar captura y registro de errores.

La virtualización no permite afirmar que Wi-Fi, GPU, suspensión o audio
funcionarán en un equipo físico.

## USB para hardware real

1. Verificar la suma SHA-256 desde `dist/`.
2. Elegir una memoria USB cuyo contenido pueda borrarse; desconectar otros
   medios externos que puedan confundirse.
3. Identificar modelo, capacidad y dispositivo. **Grabar la ISO borra el USB.**
4. Usar una herramienta de escritura de imágenes, por ejemplo GNOME Disks
   → Restaurar imagen de disco. No copiar simplemente el archivo ISO al USB.
5. Confirmar de nuevo el destino antes de escribir.
6. Reiniciar y seleccionar el USB en el menú de arranque.
7. Si Secure Boot está habilitado, esta imagen no arrancará bajo esa política.
   Antes de cambiar firmware, revisar recuperación de cifrado y configuración
   del sistema existente. No modificar opciones a ciegas.

No se incluye un comando `dd` automático para evitar elegir el disco equivocado.

## Lista de comprobación en hardware

| Prueba | Resultado |
|---|---|
| Arranque BIOS | Pendiente |
| Arranque UEFI | Pendiente |
| Sesión MATE automática | Pendiente |
| Resolución y aceleración gráfica | Pendiente |
| Ethernet y DNS | Pendiente |
| Wi-Fi y reconexión | Pendiente |
| Altavoces y auriculares | Pendiente |
| Teclado y ratón | Pendiente |
| Lectura/escritura en USB de prueba | Pendiente |
| Brillo y batería, si corresponde | Pendiente |
| Suspensión y reanudación | Pendiente |
| Apagado y reinicio | Pendiente |

## Recoger información

Desde una terminal de la sesión live:

```sh
uname -a
free -h
lspci -nnk
lsusb
rc-status
nmcli device
pactl info
```

Para diagnóstico con privilegios: `doas dmesg`.
Revisar `/var/log/lightdm/` y `/var/log/Xorg.0.log` si falla el escritorio.
Antes de compartir registros, ocultar SSID, direcciones, nombres de usuario
y cualquier otro dato personal.
