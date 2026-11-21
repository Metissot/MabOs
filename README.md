# MabOs

Una distribución pequeña de escritorio: **Alpine Linux + OpenRC + MATE**.

**MabOs es experimental.** La imagen es live, sin persistencia,
sin instalador propio y sin particionado automático. No sustituye todavía
un sistema de uso diario.

Alpha1 está comprobada en QEMU/KVM y el usuario confirmó que arranca en su PC,
aunque reportó lentitud. **Alpha2 «Oasis» ya está generada y validada en VM**:
BIOS/UEFI, identidad visual, bienvenida y Firefox por HTTPS.
La ISO anterior se conserva. El usuario confirmó el arranque físico de alpha2
desde Ventoy 1.1.18 tras volver a copiar la ISO; faltan pruebas detalladas de hardware.
Consulta las evidencias en [las pruebas](docs/PRUEBAS.md).

**Alpha3 está generada y comprobada en VM**, aplicando únicamente los pedidos
confirmados: YaruOk, Papirus-Light, panel único con lista de ventanas,
diente de león como logo y AbiWord. El fondo y las ISO anteriores se conservan.
Se revisaron BIOS, UEFI, Ventoy 1.1.18, el panel superior y la escritura en
AbiWord. Falta comprobar esta versión en el equipo físico del usuario.

**Incidencia resuelta en el equipo del usuario:** el error `invalid magic number`
desapareció al volver a copiar alpha2 al USB, sin cambiar la ISO del proyecto.
Es compatible con un problema de copia/escritura, pero no se recibió el hash
de la copia fallida para confirmar la causa exacta. Conservar alpha1 como alternativa.

## Contenido

- MATE sobre X11, LightDM y entrada automática.
- Firefox ESR, Pluma, Evince, Engrampa, calculadora y Celluloid.
- En alpha3: AbiWord como procesador de textos, sin otra suite ofimática.
- NetworkManager con acceso gráfico a Wi-Fi y Ethernet.
- PulseAudio y controles de sonido de MATE.
- Gestión de archivos, USB y herramientas básicas de diagnóstico.
- Traducciones y entorno en español; teclado ajustable desde MATE.
- Kernel LTS, firmware y controladores gráficos libres.
- Fondo Oasis y bienvenida bajo demanda.
- En alpha3: diente de león, logotipo MabOs, Papirus-Light, YaruOk y panel superior único.

Los nombres de paquetes y el perfil están en `config/` y `profiles/`.
No se incluye una suite ofimática completa, tienda ni controladores propietarios NVIDIA.
Bluetooth e impresión no forman parte de los objetivos probados de esta versión.

## Compilar en Linux x86_64

Necesitas Bash, curl, tar, sha256sum, util-linux (`unshare`, `mount`, `flock`, `chroot`)
y namespaces de usuario habilitados. No se requiere sudo.
Reserva inicialmente 15 GiB de espacio; el consumo real se medirá al compilar.

```sh
./scripts/build.sh
```

El script descarga Alpine 3.24.4, verifica el minirootfs, prepara un entorno
aislado y ejecuta `mkimage` oficial con el perfil de MabOs.
Solo escribe en este proyecto. Mantiene acceso a la red y no es una sandbox
para ejecutar código no confiable.

La versión se define en `config/version`; la construcción genera un nombre
distinto por versión y no sobrescribe la ISO alpha1.

- `dist/`: imagen, sumas y datos de compilación.
- `logs/`: registros de compilación y resolución de paquetes.
- `.work/`: entorno, fuentes, caché y claves **locales** de desarrollo.

Los repositorios de la rama v3.24 reciben actualizaciones. La receta puede
repetirse, pero no garantiza una ISO idéntica bit a bit.
La clave local firma el índice y modloop del prototipo; no es una identidad
de publicación de MabOs. No distribuir la clave privada.

## Probar

Lee primero [la guía de pruebas](docs/PRUEBAS.md). No grabes ningún disco
sin comprobar su identidad y tener copia de seguridad.

```sh
VERSION=$(cat config/version)
(cd dist && sha256sum -c "mabos-$VERSION-x86_64.iso.sha256")
```

**Sesión live:** usuario `live`, sin contraseña; `doas COMANDO` permite
administrar sin contraseña. Root está bloqueado. SSH no está habilitado.
Es una comodidad exclusiva del prototipo: no usar esta configuración en una
instalación permanente ni con datos sensibles.

Los cambios y actualizaciones desaparecen al reiniciar. No se instala nada
en los discos internos automáticamente, pero un usuario puede montarlos y
modificarlos manualmente.

## Desarrollo

```sh
python3 -m unittest discover -s tests -v
```

Después de compilar:

```sh
./scripts/check-iso.sh
```

La comprobación genera `dist/mabos-VERSION-packages.tsv` a partir del índice incluido en la
ISO, con versiones, arquitectura y licencias declaradas por cada paquete.
Antes de una publicación pública habrá que revisar las obligaciones de
redistribución y disponibilidad de código fuente de sus componentes.

Para capturar el arranque virtual (requiere QEMU y OVMF dentro del entorno
Alpine, además de acceso a `/dev/kvm`):

```sh
./scripts/enter-alpine.sh fakeroot apk add \
  '!qemu-bridge-helper' qemu-system-x86_64 ovmf seabios
python3 scripts/test-vm.py bios
python3 scripts/test-vm.py uefi
```

Las VM usan 4 GiB de RAM asignada y se ejecutan una por vez. En equipos con
poca memoria pueden provocar intercambio y ralentizar el escritorio.
Las capturas quedan en `logs/`; generarlas no equivale a validar el arranque.
Usa `--label` para conservar distintas evidencias y `--iso` para probar una
imagen anterior. Los tiempos medidos se guardan en `logs/ETIQUETA.timing.json`.

El [registro de trabajo](docs/REGISTRO.md) documenta avances y bloqueos.
Los resultados reales de pruebas se registran en `docs/PRUEBAS.md`.
La [identidad Oasis](docs/IDENTIDAD.md) y la [investigación del arranque](docs/ARRANQUE.md)
explican las decisiones, limitaciones y mediciones.

Siguientes hitos: validar hardware real, corregir problemas, medir recursos,
mejorar la experiencia y después incorporar instalación persistente.
