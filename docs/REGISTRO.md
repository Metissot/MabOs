# MabOs — registro de trabajo

## Objetivo

Distribución de escritorio pequeña y lista para tareas habituales, basada en
Alpine Linux, OpenRC y MATE. Primera entrega: ISO live experimental x86_64,
sin instalación automática ni persistencia.

## 2026-11-14 — Inicio de implementación

- Nombre elegido: **MabOs**; primera versión: **0.1.0-alpha1**.
- Arquitectura genérica x86_64; equipo inicial de prueba: Intel i7 de tercera generación.
- Anfitrión detectado: Debian 13 x86_64; aproximadamente 86 GiB libres.
- `sudo` requiere contraseña. No se dispone inicialmente de Docker, Podman o QEMU.
- Los namespaces de usuario y montaje funcionan sin privilegios.
- Se elige compilación en un rootfs Alpine aislado mediante `unshare` y `chroot`.
  No se instala software en Debian ni se solicita la contraseña.
- Base seleccionada: Alpine **3.24.4**, rama estable **v3.24**, comprobada contra
  los metadatos oficiales de publicación.
- Minirootfs verificado mediante SHA-256 fijado en el script de preparación.
  El hash proviene del mismo servidor oficial por HTTPS; no es una firma independiente.
- Se usarán herramientas oficiales `mkimage` de Alpine con un perfil propio.
- Pendiente: validar paquetes, generar ISO, comprobar arranque BIOS/UEFI y escritorio.

## Decisiones de alcance

- MATE sobre X11, acceso gráfico, navegador y herramientas cotidianas.
- Red gráfica, sonido, PDF, archivos comprimidos, multimedia y memorias USB.
- Español como idioma inicial; teclado configurable.
- Sin ofimática completa, tienda, instalador propio ni controladores propietarios.
- Sin SSH habilitado y sin instalación o particionado automático.
- Secure Boot fuera de esta primera entrega.
- No se promete compatibilidad universal ni requisitos mínimos hasta probar y medir.
- La sesión live y sus actualizaciones se pierden al reiniciar.

## 2026-11-14 — Perfil, aplicaciones y primeras comprobaciones

- Creados scripts de compilación, perfil `mkimage`, overlay de configuración,
  lista de paquetes, README, guía de pruebas y pruebas estáticas.
- Se inicializó un repositorio Git local, sin crear commits.
- Selección explícita de componentes MATE para evitar sensores, extensiones y
  fondos innecesarios del metapaquete completo.
- PulseAudio elegido para el prototipo por su integración sencilla con MATE.
- Incluido el metapaquete `lang` para resolver traducciones de las aplicaciones.
- Cuatro pruebas estáticas correctas: sintaxis, paquetes, coherencia de la
  sesión live y ausencia de comandos de particionado automático.
- Generación independiente del overlay comprobada: contiene configuración,
  lista `world`, servicios OpenRC y permisos root.
- Primer intento detenido por incompatibilidad entre `mkimage` y apk-tools 3:
  `--no-chown` ahora equivale a `--usermode`, no permitido al inicializar como root.
- Ajuste mínimo y automatizado sobre la copia local de `mkimage`: eliminar
  esa opción de `add --initdb`; se compila como root dentro del namespace y
  con fakeroot. No se deshabilita la verificación de firmas.
- Segunda compilación iniciada. Aún no se ha validado una ISO.
- Se corrigió el orden de servicios: modloop y udev-settle estarán en sysinit,
  para disponer de módulos y dispositivos antes del escritorio.
- QEMU y OVMF preparados solo dentro del entorno Alpine. El auxiliar de puente
  de QEMU produjo advertencias de propietario al instalarse en el namespace;
  no se utiliza: las pruebas usarán red de usuario, sin puentes del anfitrión.
- Comprobación QMP de una VM mínima: KVM presente y habilitado. Esto todavía
  no prueba el arranque de MabOs.
- Añadidos verificadores del overlay y de la estructura de la ISO, y un script
  para capturar el arranque BIOS/UEFI sin conectar discos del anfitrión.
- Revisión de dependencias previa a la prueba gráfica: `xinit` no depende de
  `dbus-x11`; incluirlo explícitamente antes de considerar entregable la imagen.
  Añadir también `openssl` para verificar la firma de modloop en OpenRC.
- Pendiente de endurecer la receta: invalidar la caché del overlay cuando
  cambie cualquier archivo de configuración, no solo su script generador.
- Receta endurecida para la siguiente ejecución: entradas congeladas por
  SHA-256, invalidación del overlay por su contenido completo y checksum
  fijado para el archivo de fuentes de aports.
- Añadida identidad MabOs en os-release y consola, manteniendo `ID_LIKE=alpine`.
- Siete pruebas automatizadas superadas, incluyendo lectura de índices
  firmados concatenados y rechazo de rutas inseguras en overlays.
- Overlay regenerado y comprobado con `scripts/check-overlay.py`: correcto.

## 2026-11-15 — Corrección del bloqueo y reducción de dependencias

- La compresión de modloop terminó: aproximadamente 290 MiB comprimidos.
- Se identificó un bloqueo reproducible de `scanelf` al ejecutarse con
  libfakeroot. No era una compilación activa: el proceso esperaba un semáforo.
- Se conservó el directorio temporal del kernel, se detuvo únicamente la
  cadena bloqueada y se regeneró initramfs sin repetir la compresión.
- Solución incorporada a la receta: wrapper de scanelf que elimina LD_PRELOAD
  solo al leer archivos ELF; fakeroot sigue activo para el empaquetado.
- Firma del modloop recuperado verificada con OpenSSL: `Verified OK`.
- Añadidos dbus-x11, OpenSSL y Chrony explícitamente.
- Ajustado el límite de tmpfs live a 75% de RAM; no reserva toda esa memoria.
- Se excluyó `qemu-bridge-helper` del entorno de compilación: no se utiliza
  red puente y su propietario especial provocaba errores en el namespace.
- La resolución de dependencias mostró que Atril arrastraba TeX y WebKit.
  Se sustituye por Evince; VLC se sustituye por Celluloid con interfaz gráfica.
- Una descarga de paquetes fue interrumpida por el límite de tiempo del
  comando; no produjo una ISO. Se reintentará aprovechando lo descargado.

## 2026-11-15 — Primera ISO generada

- Se corrigió la llamada anidada a fakeroot del generador oficial de overlay:
  la construcción completa ya corre bajo fakeroot.
- Se corrigió la ruta del generador: mkimage espera una ruta relativa al
  directorio de compilación, no una ruta absoluta.
- Compilación terminada correctamente. Registro:
  `logs/build-20261115T022015Z.log`.
- Archivo: `dist/mabos-0.1.0-alpha1-x86_64.iso`.
- Tamaño: **1 025 507 328 bytes**, aproximadamente **978 MiB**.
- SHA-256:
  `07c5b8d497e5693e0a501624b2bc357641a1550c74aee9b2b179340cee3f5e98`.
- Comprobaciones estructurales correctas: suma SHA-256, catálogo El Torito
  BIOS/UEFI, MBR híbrido/GPT, overlay y cobertura de los paquetes del perfil.
- Manifiesto real: `dist/packages.tsv`, **634 paquetes**, con versiones y licencias.
- Datos de compilación: `dist/build-info.txt`.
- Espacio de trabajo de compilación observado: aproximadamente 6.2 GiB,
  incluyendo cachés, descargas interrumpidas y material de recuperación.
- Iniciada prueba virtual BIOS con KVM y 3072 MiB de RAM, sin discos del
  anfitrión. La captura y su revisión siguen pendientes.
- Todavía no se ha probado en hardware real ni se ha grabado una memoria USB.

## 2026-11-15 — Arranque BIOS comprobado

- La VM BIOS arrancó desde la ISO con KVM y 3072 MiB de RAM.
- Captura revisada visualmente: `logs/vm-bios.png`.
- Confirmados escritorio MATE visible, menús en español, paneles, iconos y
  carpeta personal del usuario live; entrada automática sin intervención.
- No se infiere compatibilidad con hardware físico a partir de esta prueba.
- Iniciada prueba UEFI con diagnóstico de servicios, red, PulseAudio y Firefox.

## 2026-11-15 — UEFI, servicios y ajustes de usabilidad

- La primera imagen también arrancó por UEFI y entró automáticamente a MATE.
- Diagnóstico dentro de la VM: dbus, elogind, NetworkManager, LightDM, Chrony
  y preparación live activos en OpenRC.
- Ethernet virtual conectada, ruta predeterminada y acceso HTTPS a Alpine
  comprobados (`internet-ok`).
- PulseAudio 17 activo para el usuario live. La VM no tenía tarjeta de audio:
  destino `auto_null`. **No es una prueba de reproducción audible.**
- Memoria observada en VM con 3 GiB: aproximadamente 1.4 GiB compartidos
  (incluye el sistema live en RAM) y 1.1 GiB disponibles antes de abrir Firefox.
  No presentar los 269 MiB de la columna `used` como consumo total de la ISO.
- La orden `firefox` falló porque Alpine instala el ejecutable como
  `firefox-esr`; se verificaron el binario y el lanzador dentro del paquete.
  Se corrigió el script de prueba.
- Se detectó poco contraste en la terminal y se añadieron valores dconf
  predeterminados de texto claro y fondo oscuro.
- Añadidas asociaciones de navegador y PDF para el usuario live.
- ISO regenerada con esos ajustes; mismo nombre de versión y tamaño.
  El checksum anterior queda como referencia histórica, no como suma actual.
- Registro de la reconstrucción: `logs/build-20261115T022829Z.log`.
- **SHA-256 actual:**
  `a3fedbcfb8f5e0353d0c0c84a564ea1efb15d7889d069f93f315600382bd60f5`.
- Integridad, estructura y overlay de la imagen actual comprobados.
- Repetición de pruebas UEFI y BIOS de la imagen actual en curso, una VM a
  la vez. Se comprobará también la apertura gráfica de Firefox.

## 2026-11-15 — Espera de arranque y Wi-Fi

- El reintento con una pausa fija de 90 segundos intentó enviar comandos
  antes de que el escritorio estuviera disponible y agotó el diagnóstico.
  La captura mostraba OpenRC todavía preparando modloop; no se interpreta
  como fallo confirmado de MATE.
- El script ahora espera al prompt de consola posterior a OpenRC y concede
  tiempo adicional a la sesión gráfica, con límite máximo configurable.
- Se habilitaron explícitamente wpa_supplicant y su servicio OpenRC para
  preparar las pruebas posteriores de Wi-Fi en hardware real.
- ISO reconstruida y comprobada. Registro:
  `logs/build-20261115T023314Z.log`.
- **SHA-256 actual:**
  `ddfb3a08b747ff8d441da8ade665ded92cc6c3d166f8fb6ded577233a44a0d98`.
- Se repiten UEFI con diagnóstico y BIOS sobre esta imagen.

## 2026-11-15 — Validación virtual de la ISO actual completada

- Imagen comprobada:
  `ddfb3a08b747ff8d441da8ade665ded92cc6c3d166f8fb6ded577233a44a0d98`.
- Arranque BIOS y UEFI correctos; capturas revisadas visualmente.
- Sesión MATE automática en español confirmada en ambos modos.
- Terminal abierta desde la sesión; diagnóstico ejecutado como usuario live
  y con doas para leer servicios y enviar la salida al puerto serie virtual.
- Servicios OpenRC activos: dbus, elogind, mabos-live, wpa_supplicant,
  NetworkManager, LightDM y Chrony.
- Ethernet virtual, ruta predeterminada y acceso HTTPS comprobados.
- PulseAudio activo para live; salida nula porque no se emuló una tarjeta
  de audio. No se afirma que el audio físico esté validado.
- Firefox ESR 140.12.0esr abrió gráficamente la web de Alpine por HTTPS,
  confirmado en `logs/vm-uefi-apps.png`.
- Capturas y registro final: `logs/vm-bios.png`, `logs/vm-uefi.png`,
  `logs/vm-uefi-apps.png`, `logs/vm-uefi.serial.log`.
- Esta imagen es apta como **prototipo experimental para pruebas manuales**,
  no como versión estable ni sistema de producción.
- Pendientes detallados en `docs/PRUEBAS.md`: hardware real, Wi-Fi, audio,
  aplicaciones restantes, apagado, reinicio, suspensión e instalación.
- No se ha grabado ningún USB ni modificado discos internos.

## Seguridad de las pruebas

- No grabar memorias USB sin identificar el dispositivo y confirmar con el usuario.
- No probar con discos reales conectados a una máquina virtual.
- No confundir una compilación correcta con un escritorio validado.
- Registrar pruebas realizadas y pendientes, sin inventar resultados.
- Las claves de firma del prototipo permanecen en `.work/`, fuera del código fuente.

## 2026-11-15 — Inicio de MabOs Oasis / alpha2

- El usuario informa que alpha1 funciona en su equipo y que el arranque
  tarda mucho. No se han medido todavía tiempos en ese hardware.
- Confirmada identidad visual: cactus como logo, fondo relajante y Papirus.
- La ISO alpha1 se conserva sin sobrescribir. Datos de compilación y paquetes
  guardados también con nombres específicos de esa versión.
- Nueva versión centralizada: `config/version`, inicialmente 0.1.0-alpha2.
- Dibujados SVG originales de paisaje Oasis y cactus; licencia CC0.
- Configurados Papirus, YaruGreen, tipografía, fondo y logo del menú.
- Configurada pantalla LightDM coherente y bienvenida bajo demanda con acceso
  a red, teclado, apariencia y guía; sin autoarranque adicional.
- Confirmada disponibilidad de Papirus y Zenity en Alpine.
- Se eliminó KMS del initramfs; los gráficos y firmware permanecen en modloop.
  Pendiente de generar, medir y probar la imagen resultante.
- Añadidas entradas de arranque normal y diagnóstico, preservando firmas.
- Añadidas pruebas de arte, menú, versión y configuración: 12 pruebas pasan.
- El overlay se genera con la versión sustituida en los archivos de identidad.
- Medición exploratoria alpha1: 124.49 s hasta getty, con carga concurrente;
  no se utiliza como comparación controlada.
- Documentación de criterios visuales: `docs/IDENTIDAD.md`.
- Investigación y metodología de arranque: `docs/ARRANQUE.md`.

## 2026-11-15 — ISO Oasis generada

- Construcción completada: `logs/build-20261115T175913Z.log`.
- Imagen: `dist/mabos-0.1.0-alpha2-x86_64.iso`.
- SHA-256:
  `5a9ea6c5b84e05f8f46385b871a408866a4af4dd38b04cbb8878c672928836ec`.
- Tamaño: 907 018 240 bytes, 865 MiB.
- Initramfs: 22 542 320 bytes (21.5 MiB), aproximadamente 87.5% menor
  que el de alpha1 (179 926 528 bytes).
- La reducción del archivo no se presenta como reducción equivalente del
  tiempo total de arranque.
- Firma y montaje de modloop no deshabilitados; firmware y microcódigo conservados.
- Estructura híbrida BIOS/UEFI, overlay y 637 paquetes verificados.
- Manifiesto: `dist/mabos-0.1.0-alpha2-packages.tsv`.
- Fondo y cactus renderizados y revisados; vistas previas en `logs/`.
- 12 pruebas automatizadas correctas.
- Iniciada comparación alpha1/alpha2 UEFI y prueba BIOS de alpha2,
  secuencialmente y sin construcción concurrente. Pendiente de resultados.

## 2026-11-15 — Revisión visual y corrección de Papirus

- El primer candidato Oasis arrancó por BIOS/UEFI con fondo y cactus visibles.
- Firefox abrió la web de Alpine por HTTPS; servicios y PulseAudio activos.
- Comparación sin compilación concurrente: alpha1 109.38 s y primer candidato
  alpha2 75.57 s hasta getty, UEFI, 3072 MiB y dos CPU virtuales. Es una
  pareja de observaciones, no un promedio ni una garantía para USB físico.
- La captura reveló iconos antiguos: Papirus estaba instalado, pero la
  preferencia se escribió en `/org/mate/interface/`.
- El esquema real `org.mate.interface` usa `/org/mate/desktop/interface/`.
  Se corrigió la ruta y la prueba estática correspondiente.
- Añadidos colores de etiquetas de Caja para legibilidad sobre el fondo claro.
- El diagnóstico puede exigir Papirus/YaruGreen (`--branding`) y capturar
  la bienvenida, además de comprobar la apertura del navegador.
- Imagen reconstruida: `logs/build-20261115T182720Z.log`.
- SHA-256 actual:
  `b24e18c2c2d52ea03faadb2d70509464b3123085f365d1a30e73d4e1082d8ef5`.
- Integridad y estructura correctas. Repetición de pruebas de esta imagen
  en curso; no se presenta el candidato anterior como validación final.

## 2026-11-15 — Papirus confirmado y ajuste final de bienvenida

- Capturas revisadas: Papirus, cactus y fondo Oasis visibles en BIOS y UEFI.
- GSettings del usuario confirmó `'Papirus'` y `'YaruGreen'`.
- La terminal y las etiquetas del escritorio tienen contraste legible.
- Una captura de bienvenida mostró advertencias EGL en la VM sin aceleración,
  y el test posterior escribió parte del comando en una ventana equivocada.
  No se interpreta como fallo del navegador: Firefox funcionó en la prueba previa.
- El diálogo usa ahora Cairo, apropiado para una lista simple y GPU antiguas.
  No se cambia el renderizado de Firefox ni de otras aplicaciones.
- El test abre aplicaciones desde el diálogo global de MATE en vez de depender
  del foco de la terminal después de cerrar la bienvenida.
- Reconstrucción: `logs/build-20261115T183308Z.log`.
- SHA-256 actual:
  `abdaf93028f402710f1548715ab4803a50f7555a1eef6d0766368ebc2cc96cc2`.
- Integridad, estructura y 12 pruebas estáticas correctas.
- Validación de esta imagen en curso con etiquetas `oasis-release-uefi` y
  `oasis-release-bios`, incluyendo bienvenida y navegador.

## 2026-11-15 — Oasis alpha2 lista para pruebas

- ISO final comprobada:
  `dist/mabos-0.1.0-alpha2-x86_64.iso`, 907 018 240 bytes (865 MiB).
- SHA-256:
  `abdaf93028f402710f1548715ab4803a50f7555a1eef6d0766368ebc2cc96cc2`.
- BIOS y UEFI correctos en KVM con 3072 MiB; capturas revisadas.
- Fondo Oasis, cactus en Aplicaciones, Papirus y etiquetas legibles confirmados.
- La sesión confirmó Papirus/YaruGreen por GSettings.
- Bienvenida visible y legible con Cairo; Firefox abrió Alpine por HTTPS
  después de cerrar el diálogo. No se probaron todos los botones de bienvenida.
- Red virtual y servicios OpenRC activos; PulseAudio activo con salida nula,
  sin afirmar que se haya probado reproducción audible.
- Capturas finales bajo `logs/oasis-release-*`.
- Tiempo hasta getty de la imagen final: UEFI 86.34 s, BIOS 60.48 s.
- Referencia alpha1 UEFI: 109.38 s sin compilación concurrente. La reducción
  observada es de aproximadamente 21%, pero son muestras individuales;
  no equivale a una promesa de arranque 21% más rápido en el USB del usuario.
- La ISO alpha1 continúa disponible e intacta como alternativa.
- Pendiente: medir alpha2 en el equipo físico, comprobar GPU, Wi-Fi, audio,
  suspensión, apagado y reinicio. Sigue siendo live experimental sin persistencia.
- Próxima mejora grande si la carga sigue siendo lenta: estudiar un sistema
  live preinstalado, no reinstalar cientos de paquetes en cada encendido.

## 2026-11-15 — Incidencia de arranque con Ventoy

- El usuario reportó `invalid magic number` y después
  `you need to load the kernel first` en alpha2 usando Ventoy, modo normal.
- Alpha1 sí inicia en el mismo entorno según el usuario.
- Se reconoce una carencia de la validación anterior: las VM arrancaban
  desde CD virtual, no a través de Ventoy.
- La ISO alpha2 del proyecto conserva su SHA-256 esperado. Falta comprobar
  la copia que está en el USB y conocer la versión de Ventoy del usuario.
- Se extrajeron ambos kernels: son idénticos, SHA-256
  `f1a98c494ca3e640bda504c1cf56cf2f7191ab6b7842a96b30b8a47fae5e6375`.
- Ambos tienen cabecera válida bzImage x86_64, kernel Alpine 6.18.63-0-lts.
- Diferencias de GRUB: títulos, formato, orden de microcódigo y entrada de
  diagnóstico. Initramfs reducido. Ninguna se declara causa sin reproducir.
- Descargado Ventoy oficial 1.1.18 y comprobado contra su SHA-256 publicado:
  `d86ff9de63d94c8b8f1f6b14d23c55af4b88e8207bf2893890892a6a97b1ad54`.
- Creado un laboratorio en un archivo regular de 3 GiB, MBR/FAT32,
  con los archivos oficiales de arranque y ambas ISO. No se ejecutó
  Ventoy2Disk ni se accedió a dispositivos físicos para escribir.
- La inspección inicial UEFI llegó al GRUB de MabOs sin mostrar el error
  reportado; la pantalla negra posterior no se interpreta como éxito.
- En curso prueba completa con Ventoy 1.1.18, modo normal, en disco virtual.
- La versión, sistema de archivos y firmware del USB real pueden diferir.
- No se ha generado una ISO nueva ni declarado solucionado el problema.

## 2026-11-15 — Resultado del laboratorio Ventoy

- Ventoy 1.1.18, modo normal, UEFI, disco virtual IDE con MBR/FAT32:
  alpha2 llegó al escritorio MATE con fondo Oasis y Papirus.
- Captura revisada: `logs/ventoy-alpha2-normal-full-timeout.png`.
- El proceso automático agotó su espera porque no apareció el prompt serie
  que usa como señal de OpenRC. La captura demuestra que MATE ya estaba
  iniciado. Se corrigió el mensaje del test para no afirmar un fallo de
  arranque basándose solo en ausencia de esa señal.
- No se conoce el instante exacto en que apareció el escritorio en esta
  prueba: el límite de 360 s no se presenta como tiempo de arranque.
- No se reprodujo `invalid magic number` con esta configuración.
- El caso del usuario continúa abierto: hacen falta versión de Ventoy,
  checksum de la copia del USB y resultado del modo GRUB2.
- No se modificó la ISO ni se declara una reparación sin evidencia.

## 2026-11-15 — Arranque físico confirmado tras recopiar

- El usuario identificó Ventoy 1.1.18 y decidió borrar únicamente la copia
  alpha2 del USB y volver a copiarla.
- Después confirmó: «funciono correctamente».
- La incidencia de arranque queda resuelta en ese equipo según su reporte,
  sin modificar el kernel ni generar otra ISO.
- El resultado es compatible con una copia o escritura incompleta/corrupta,
  pero no se dispone del checksum de la copia fallida para demostrar la causa.
- No se afirma compatibilidad universal con Ventoy ni se dan por probados
  Wi-Fi, audio, suspensión u otros componentes sin pruebas específicas.
- Siguiente paso recomendado: comparar el tiempo de arranque físico y revisar
  red, sonido, gráficos, apagado y reinicio.

## 2026-11-15 — Acuerdo de alcance y personalización pendiente

- Solo se harán cambios solicitados explícitamente por el usuario.
- Si un cambio requiere ajustes adicionales, se explicarán y se esperará
  autorización antes de realizarlos.
- No se añadirán aplicaciones, ajustes o personalizaciones por iniciativa propia.
- Se conservará la ISO que funciona, sin sobrescribirla.
- Antes de implementar se confirmará el alcance.

### Solicitud anotada, NO implementada

- Tema de interfaz: **YaruOk**.
- Controles: **YaruOk**.
- Borde de ventana: **YaruOk**.
- Iconos: **Papirus-Light** (escrito «papirus-Ligth» en la solicitud).
- No aplicar todavía a la configuración ni construir una nueva ISO.
- Esta entrada solo registra el pedido. No se modificaron temas, controles,
  bordes, iconos ni archivos de la imagen. Se requiere autorización posterior
  para implementar.

## 2026-11-15 — Sonido y Wi-Fi confirmados; paneles e identidad pendientes

### Pruebas comunicadas por el usuario

- El sonido y el Wi-Fi funcionaron muy bien en el equipo físico.
- Es una confirmación del usuario; no se dispone de registros ni del detalle
  de dispositivos y escenarios probados. No se infiere que micrófono,
  Bluetooth, suspensión o todo el hardware estén comprobados.

### Nuevas solicitudes anotadas, NO implementadas

- Escritorio MATE:
  - Quitar el panel 2, actualmente el panel inferior.
  - Conservar el panel 1, actualmente el superior.
  - Añadir la lista de ventanas al panel 1 para ver las aplicaciones abiertas.
  - No se ha solicitado trasladar otros elementos del panel eliminado.
- Identidad:
  - Sustituir el logo de cactus por un diente de león
    (**Taraxacum officinale**) como icono de la distribución.
  - Propuesta de logotipo: **MabOs**, con la **O** representada por un diente
    de león y sus semillas/vilanos desprendiéndose con el viento.
  - Referencia cultural y visual solicitada: **Catamarca**.
  - La referencia al cactus como logo queda reemplazada para la próxima
    implementación; no se han modificado los archivos gráficos actuales.
  - No se interpreta este pedido como autorización para cambiar el fondo
    de pantalla; cualquier ajuste adicional se consultará primero.
- Se mantienen pendientes YaruOk para tema, controles y borde de ventana,
  y Papirus-Light para iconos.
- Continúa la etapa de anotación: no se modificó la configuración de MATE,
  los paneles, el logo, el fondo ni la ISO. Se espera autorización para implementar.

## 2026-11-15 — AbiWord pendiente

- Añadir **AbiWord** como procesador de textos de la distribución, para
  redactar y editar documentos.
- AbiWord no es una suite ofimática completa: no se han solicitado una hoja
  de cálculo ni una aplicación de presentaciones.
- Solicitud anotada, NO implementada. No se cambió la lista de paquetes,
  no se instaló software ni se generó una nueva ISO.

## 2026-11-15 — Implementación autorizada de todos los pendientes / alpha3

- Antes de implementar se consultó el alcance: el usuario eligió **Todos los
  pendientes**, incluyendo crear otra ISO y conservar las anteriores.
- Versión nueva: 0.1.0-alpha3. No se sobrescriben alpha1 ni alpha2.
- Configurados controles GTK/MATE YaruOk, bordes YaruOk e iconos Papirus-Light.
  Se comprobó que ambos temas existen en los paquetes ya incluidos.
- Definido un layout MATE con un solo panel superior: menú, lista de ventanas,
  indicadores y reloj. No se trasladan otros elementos del panel inferior.
- Sustituido el logo activo de cactus por diente de león y dibujado el logotipo
  MabOs con la O formada por semillas al viento. Referencia del usuario: Catamarca.
- El archivo del fondo se comparó con alpha2 y permanece idéntico, SHA-256:
  `3687eb5dadc2561f3667b4d9c3c45ad748185fcd731c98502f885c2f8b6af01f`.
- Añadido AbiWord, sin LibreOffice, Gnumeric u otra aplicación ofimática.
- Resolución previa de paquetes: ningún paquete anterior se elimina o cambia
  de versión. Solo se añaden abiword, goffice, goffice-lang, libgsf, libgsf-lang
  y wv; son AbiWord y sus dependencias.
- No se cambian kernel, arranque, red, audio ni configuración de seguridad.
- Vistas previas del icono y logotipo en `logs/alpha3-*-preview.png`.
- 18 pruebas automatizadas correctas, incluyendo panel único y fondo intacto.
- Se inició la construcción y comprobación de alpha3. Todavía no se declara
  lista: faltan revisión de escritorio, AbiWord y pruebas de arranque.

## 2026-11-15 — Alpha3 generada; pruebas en curso

- Imagen: `dist/mabos-0.1.0-alpha3-x86_64.iso`, 915 406 848 bytes (873 MiB).
- SHA-256:
  `0caa333843d0a9e16a4e232ebb35a490a0ba2efda94121f042c86663be3b7883`.
- Suma, arranque híbrido BIOS/UEFI y overlay verificados; 643 paquetes.
- Comparación posterior del manifiesto: ningún paquete anterior se elimina
  ni cambia de versión; se confirman únicamente las seis altas previstas.
- Initramfs idéntico a alpha2, SHA-256:
  `2fd7e79404ca11a7d8559277a126563091e19b95033736590465c96233fb0600`.
- SHA-256 de alpha1 y alpha2 comprobados: ambas imágenes siguen intactas.
- Se añadió alpha3 al disco virtual Ventoy del laboratorio y se seleccionó
  como imagen predeterminada. No se escribió ningún dispositivo físico.
- Se iniciaron pruebas secuenciales UEFI con AbiWord/identidad, BIOS y Ventoy
  normal en disco virtual. No se considera validada antes de revisar las capturas.

## 2026-11-15 — Alpha3 validada en laboratorio

- Se revisaron las capturas de UEFI, BIOS y Ventoy 1.1.18 en modo normal
  sobre disco virtual. MATE inició correctamente en las tres pruebas.
- GSettings confirmó `'Papirus-Light'`, controles `'YaruOk'`, bordes
  `'YaruOk'`, paneles `['top']` y objetos menú, lista de ventanas,
  indicadores y reloj.
- Capturas con AbiWord y Firefox muestran sus botones en el único panel
  superior; el panel inferior no está presente.
- Icono de diente de león visible en Aplicaciones. Logotipo completo incluido
  en la imagen y revisado como vista previa.
- AbiWord 3.0.8 abrió un documento y aceptó dos líneas de texto de prueba.
  No se afirma que todos sus formatos, guardado o exportación estén validados.
- Firefox abrió la web de Alpine por HTTPS; servicios y red virtual activos.
- La primera captura UEFI fue temprana y mostró fondo negro; las posteriores
  y las de BIOS/Ventoy muestran Oasis. El archivo del fondo sigue idéntico.
- La advertencia gráfica de `abiword --version` bajo doas es del chequeo CLI
  sin autorización X de root; AbiWord gráfico funcionó como usuario live.
- Evidencias principales: `logs/alpha3-uefi-abiword.png`,
  `logs/alpha3-uefi-apps.png`, `logs/alpha3-bios.png`,
  `logs/alpha3-ventoy-normal.png` y `logs/alpha3-uefi.serial.log`.
- Se aplicaron solamente los pendientes autorizados y sus ajustes de
  integración/prueba. Fondo, initramfs y versiones anteriores conservados.
- ISO lista para pruebas físicas experimentales:
  `dist/mabos-0.1.0-alpha3-x86_64.iso` (873 MiB).
- SHA-256:
  `0caa333843d0a9e16a4e232ebb35a490a0ba2efda94121f042c86663be3b7883`.
- Sonido y Wi-Fi ya habían sido confirmados por el usuario en alpha2.
  En alpha3 aún requieren comprobación física; no se dan por validados
  suspensión, apagado, reinicio u otros componentes no probados.

## 2026-11-15 — Comprobación inicial de Trinity sobre Alpine

- El usuario autorizó iniciar la exploración de Trinity como escritorio
  experimental separado, conservando alpha3 con MATE.
- Antes de modificar la distribución se consultaron los repositorios
  configurados: Alpine v3.24 main/community, arquitectura x86_64.
- La búsqueda exacta por nombres trinity*, tde* y tqt* no devolvió paquetes.
- El catálogo oficial de Alpine v3.24 tampoco devolvió paquetes para
  *trinity* y tqt*. La documentación de instalación de Trinity consultada
  no incluye Alpine entre sus instrucciones de instalación por paquetes.
- Referencias:
  - https://pkgs.alpinelinux.org/packages?name=*trinity*&branch=v3.24&arch=x86_64
  - https://pkgs.alpinelinux.org/packages?name=tqt*&branch=v3.24&arch=x86_64
  - https://wiki.trinitydesktop.org/Category:Documentation
- No se declara imposible usar Trinity con musl; falta comprobarlo mediante
  compilación y pruebas. Tampoco se consideran adecuados los binarios de
  otras distribuciones sin comprobar compatibilidad.
- Continuar requeriría preparar paquetes propios de TQt/Trinity o evaluar
  otra fuente de paquetes. Según el acuerdo de alcance, se solicita
  autorización antes de instalar dependencias de compilación, añadir
  repositorios externos o cambiar la receta de la ISO.
- No se modificaron config/version, paquetes, escritorio, arranque, logo
  ni imágenes. No se ha generado una ISO con Trinity.
- El regreso al cactus continúa como solicitud pendiente; no se aplica
  automáticamente como parte de esta investigación.

## 2026-11-15 — Laboratorio aislado para TQt autorizado

- El usuario autorizó instalar dependencias y probar únicamente TQt, antes
  de construir Trinity o integrar otro escritorio en una ISO.
- Creado `experiments/trinity/enter-alpine.sh`, con raíz independiente en
  `.work/trinity/rootfs`. No modifica `.work/alpine` ni su script de entrada.
- Bootstrap Alpine 3.24.4 verificado con el SHA-256 ya utilizado.
- Dependencias instaladas exclusivamente desde v3.24 main/community:
  build-base, perl, linux-headers, pkgconf y cabeceras X11, fontconfig,
  freetype, zlib, PNG, JPEG, SM e ICE.
- Herramientas comprobadas: GCC 15.2.0, musl 1.2.6 y Make 4.4.1.
- APK terminó con estado 1 por no poder conservar el propietario de
  `usr/sbin/unix_chkpwd` (dependencia transitiva linux-pam) dentro del
  namespace sin privilegios. Las herramientas quedaron instaladas; no se
  cambian permisos del anfitrión ni se usa ese ejecutable para compilar.
- Registros: `logs/trinity/dependencies.log` y `logs/trinity/environment.log`.
- Descarga de TQt R14.1.7 iniciada desde el servidor oficial. La conexión es
  lenta; se reanudó la descarga tras el límite inicial de tiempo.
- SHA-512 publicado obtenido; se comprobará antes de extraer o ejecutar
  las fuentes. Todavía no se ha configurado ni compilado TQt.
- MATE, configuración de lanzamiento, logo e ISO anteriores sin cambios.

## 2026-11-15 — Fuentes TQt verificadas; primer intento iniciado

- Descarga oficial finalizada: `tqt-trinity-14.1.7.tar.xz`.
- SHA-512 comprobado con el archivo publicado por Trinity:
  `394d6201f2eaf7ab128d1e586485d6bbbf4dc3eb7f14d91ffa4785aea25f925fe8221a742eddeeaeccdb15f5334082dda3e3809af76f999b06282453abae3e40`.
  Esta comprobación no equivale a verificar la firma GPG.
- Leídos README.md, INSTALL, configure y las especificaciones de GCC.
  El README identifica el toolkit como TQt 3.5.0, distribuido en R14.1.7.
- Receta reproducible: `experiments/trinity/build-tqt.sh`, ejecutada con
  `sh experiments/trinity/enter-alpine.sh /bin/sh /work/experiments/trinity/build-tqt.sh`.
- Primer intento sin parches: biblioteca compartida, hilos, release,
  bibliotecas del sistema para zlib/PNG/JPEG y plataforma linux-g++.
  Desactivados OpenGL, MNG, NIS y CUPS en esta prueba limitada; omitidos
  ejemplos y tutorial. Esto no define las funciones de una futura ISO.
- Prefijo reservado `/opt/tqt-experiment` dentro del laboratorio.
  No se ejecuta `make install`. Compilación limitada a `make -j1`.
- Salida del primer intento: `logs/trinity/build-tqt-attempt1.log`.
  Resultado todavía pendiente; no se declara compatible con musl.

## 2026-11-15 — TQt compila y supera prueba básica nativa con musl

- Primer intento: la biblioteca, plugins y herramientas compilaron sin
  errores de C/C++. El `make` general acabó con estado 2 porque entró en
  `tutorial/`, sin Makefile tras `-nomake tutorial`.
- Ajustada únicamente la receta experimental a `make -j1 sub-tools`:
  este objetivo incluye biblioteca, plugins y herramientas sin tutoriales
  ni ejemplos. Segundo intento finalizado con estado 0.
- No se aplicaron parches a las fuentes TQt ni se cambió el compilador.
- Registros completos: `logs/trinity/build-tqt-attempt1.log` y
  `logs/trinity/build-tqt-attempt2.log`.
- Validación reproducible: `experiments/trinity/validate-tqt.sh`.
  `tqmake` generó el Makefile de `smoke.pro`; GCC compiló y enlazó el
  programa con `libtqt-mt.so.3.5.0`.
- `ldd` resolvió las dependencias con `/lib/ld-musl-x86_64.so.1`,
  sin glibc ni capas de compatibilidad.
- El ejecutable terminó con estado 0 y mostró:
  `TQt 3.5.0: UTF-8, thread, PNG and event loop OK`.
  Comprueba texto UTF-8, creación/espera de hilo, escritura/lectura PNG
  y temporizador sobre el bucle de eventos sin servidor gráfico.
- Se corrigió el programa de prueba para usar `TQ_SLOT`, API de TQt,
  en vez de `SLOT`; no fue un fallo ni un parche del toolkit.
- Particularidad pendiente: `tqmake -v` imprime versión pero retorna 154,
  y `tqmoc -v` retorna 1. La generación real de Makefiles y la compilación
  sí funcionaron; las salidas de versión no se consideran prueba suficiente.
- Resultado en `logs/trinity/validation.log`. No se ejecutó `make install`.
- Conclusión limitada: TQt es compilable y ejecutable en esta configuración
  Alpine/musl. No demuestra todavía funcionamiento gráfico, compatibilidad
  de todos los módulos ni viabilidad del escritorio Trinity completo.
- No se construyeron otros módulos Trinity, paquetes APK ni otra ISO.
  MATE, logo y configuración de la distribución siguen sin cambios.
- Antes de ampliar a los siguientes módulos se consultará al usuario.

## 2026-11-15 — Continuación autorizada: dependencias de Trinity

- El usuario respondió «hazlo» a continuar con las siguientes dependencias
  en el laboratorio. No se amplía a sustituir MATE ni a generar una ISO.
- Añadidos CMake 4.2.3 y Ninja (proveído por samurai) desde Alpine oficial.
  APK conserva el estado de error de propietario anotado anteriormente;
  las nuevas herramientas sí se ejecutan.
- Fuentes oficiales R14.1.7 de tde-cmake y tqtinterface descargadas y
  verificadas mediante sus SHA-512 publicados.
- Receta: `experiments/trinity/build-stage2.sh`.
- Instalado TQt en `/opt/tqt-experiment` exclusivamente dentro del rootfs
  experimental. tde-cmake instala sus módulos en el CMake del laboratorio.
- tqtinterface configurado, compilado e instalado correctamente en
  `/opt/trinity-experiment`, sin parches. Estado final de la receta: 0.
- `pkg-config --modversion tqt` devuelve 14.1.0, valor definido por las
  propias fuentes R14.1.7; `libtqt.so.4.2.0` enlaza con TQt/musl y sus
  dependencias se resuelven dentro del laboratorio.
- Registro: `logs/trinity/build-stage2.log`.
- Iniciada descarga de arts, dbus-tqt, dbus-1-tqt, tqca y libart-lgpl
  para inspeccionar y probar las siguientes dependencias. Receta de
  descarga: `experiments/trinity/fetch-dependencies.sh`.
- Configuración de lanzamiento, arte e ISO anteriores sin cambios.

## 2026-11-15 — Prueba de las siguientes cinco dependencias iniciada

- Finalizada descarga y verificación SHA-512 de arts, dbus-tqt, dbus-1-tqt,
  tqca y libart-lgpl R14.1.7. Evidencia: `logs/trinity/sources-stage3.log`.
- Instaladas cabeceras oficiales de GLib, ALSA, audiofile, Vorbis, MAD,
  D-Bus y OpenSSL únicamente en el laboratorio.
- La prueba básica contra TQt instalado y las opciones pkg-config de
  tqtinterface terminó con estado 0: `logs/trinity/validation-stage2.log`.
- Iniciada `experiments/trinity/build-stage3.sh`, con CMake/Ninja,
  prefijo `/opt/trinity-experiment` y paralelismo 1.
- Se evalúa cada módulo por separado, sin instalar los que fallen.
  Documentación de arts/libart desactivada; el resto conserva sus opciones
  predeterminadas, incluido TQCA TLS y ALSA en aRts.
- Resumen de estados en `logs/trinity/build-stage3.log`; salida detallada
  en `logs/trinity/build-<módulo>.log`. Resultados pendientes.
- Todavía no se construyen tdelibs/tdebase ni una ISO; no se modifica MATE.

## 2026-11-15 — Primer resultado de dependencias: falta Bash

- Primer pase terminado: libart-lgpl compilado e instalado (estado 0).
  aRts, dbus-tqt, dbus-1-tqt y tqca fallaron (estado 1).
- Causa común comprobada: `tmoc` existe, pero su intérprete es
  `#!/bin/bash` y el rootfs mínimo no incluía Bash. El mensaje
  «tmoc: not found» no indicaba ausencia del archivo ni incompatibilidad
  C++/musl.
- Añadido Bash desde los repositorios oficiales solo al laboratorio.
  Registro APK: `logs/trinity/dependencies-bash.log`.
- Preservadas salidas del primer pase como
  `logs/trinity/build-<módulo>-attempt1.log` y
  `logs/trinity/build-stage3-attempt1.log`.
- Segundo pase iniciado con la misma receta y opciones, sin parches.
  Resultado todavía pendiente; no se afirma que las dependencias completas
  ni el escritorio estén validados.

## 2026-11-15 — Cinco dependencias compiladas y comprobaciones básicas

- Segundo pase finalizado con estado 0 en los cinco módulos: arts,
  dbus-tqt, dbus-1-tqt, tqca (biblioteca y plugin TLS) y libart-lgpl.
- No fue necesario aplicar parches: añadir Bash resolvió el bloqueo común.
- Bibliotecas instaladas solo en el laboratorio, en los prefijos TQt y
  Trinity experimentales. No son aún paquetes APK distribuibles.
- Receta de validación: `experiments/trinity/validate-stage3.sh`.
  Resultado completo: `logs/trinity/validation-stage3.log`, estado 0.
- Compilados los ejecutables de prueba de libart; CTest pasó sus cinco
  pruebas habilitadas: testpat, dash, dist, intersect y testuta.
  No se habilitó la prueba gradient, desactivada por upstream.
- `ldd` resolvió las dependencias de las bibliotecas instaladas y del
  plugin criptográfico sin errores de bibliotecas o símbolos ausentes.
- Programa `smoke-tqca.cpp` compilado y ejecutado: el proveedor TLS se
  descubre y carga correctamente (`TQCA TLS provider: OK`).
  Esto no valida negociaciones TLS, certificados ni navegación HTTPS.
- `dbusxml2qt3 --help` se ejecutó con estado 0. No se afirma validación
  funcional de D-Bus, sesiones de escritorio ni audio aRts.
- Sintaxis de los scripts experimentales comprobada con `sh -n`.
- SHA-256 de la ISO alpha3 comprobado nuevamente: coincide.
- Balance: TQt, tde-cmake, tqtinterface y las cinco dependencias probadas
  compilan sobre Alpine/musl sin parches. Sigue pendiente compilar tdelibs
  y tdebase y validar el escritorio gráfico real.
- No se inició tdelibs/tdebase, no se generó otra ISO, no se sustituyó MATE
  ni se cambió el logo. La siguiente ampliación requiere autorización.

## 2026-11-15 — Prueba de tdelibs autorizada

- El usuario autorizó continuar con tdelibs en el mismo laboratorio aislado.
  Se mantiene fuera del alcance tdebase, sustituir MATE o generar otra ISO.
- Iniciada descarga de las fuentes oficiales R14.1.7 de tdelibs.
  SHA-512 publicado obtenido; se verificará antes de extraer las fuentes.
- Se inspeccionarán las comprobaciones actuales de CMake antes de escoger
  dependencias y opciones. No se presuponen las de guías antiguas.
- Espacio libre comprobado: aproximadamente 72 GiB.
- No hay todavía un resultado de configuración o compilación de tdelibs.

## 2026-11-15 — tdelibs configurado; compilación iniciada

- Fuentes R14.1.7 verificadas con el SHA-512 oficial y extraídas.
- Dependencias oficiales añadidas solo al laboratorio: file-dev,
  libxml2-dev, libxslt-dev, cups-dev, eudev-dev, libxcomposite-dev,
  libxt-dev, iceauth, acl-dev y attr-dev.
- Receta: `experiments/trinity/build-tdelibs.sh`, CMake/Ninja Release,
  prefijo experimental, libart activado y demás opciones predeterminadas.
  Paralelismo 1. Todavía no ejecuta instalación de tdelibs.
- Primer configure bloqueado al consultar arts.pc: declaraba `libmad`,
  pero Alpine suministra `mad.pc`. Se identificó una detección almacenada
  de MAD al reconfigurar aRts; no faltaba la biblioteca.
- Se regeneró e instaló aRts eliminando solo variables de caché `*MAD*`
  (`cmake -U '*MAD*'`), sin parches en fuentes ni alias ficticios.
  La receta stage3 también incorpora esta opción para aRts.
- arts.pc ahora declara `alsa audiofile mad vorbis vorbisfile`, y
  `pkg-config --modversion arts` funciona (1.5.10).
- Registro de reparación: `logs/trinity/rebuild-arts-pkgconfig.log`.
- Segundo configure de tdelibs finalizado: Ninja generó 2914 tareas.
  La ejecución inicial alcanzó el límite de 120 segundos sin un error
  de compilación registrado; se reanudó incrementalmente en segundo plano.
- Logs conservados: `logs/trinity/build-tdelibs-attempt1.log`,
  `logs/trinity/build-tdelibs-attempt2.log` y
  `logs/trinity/build-tdelibs-attempt3.log` (ejecución activa).
- Resultado todavía pendiente. MATE, logo, arranque e ISO sin cambios.

## 2026-11-15 — Compilación de tdelibs terminada

- La ejecución `build-tdelibs-attempt3.log` terminó correctamente, incluida
  la última tarea Ninja de enlace de dcopserver. No se aplicaron parches
  a las fuentes tdelibs ni fue necesario desactivar módulos adicionales.
- Esto acredita compilación, no funcionamiento del escritorio.
- No se ha instalado tdelibs ni iniciado tdebase.
- Iniciada receta `experiments/trinity/validate-tdelibs.sh`: revisión de
  enlaces de tdecore, tdeui y tdeio, y compilación/ejecución de seis pruebas
  upstream de tdecore sin servidor gráfico.
- Pruebas seleccionadas: kcharsetstest, kglobaltest, kmacroexpandertest,
  krfcdatetest, kstringhandlertest y kurltest. Se usa HOME/TDEHOME propio
  bajo `.work/trinity/test-home-tdelibs`, sin sesión gráfica del anfitrión.
- Resultado pendiente en `logs/trinity/validation-tdelibs.log`.
- Catálogo de las 45 pruebas CTest declaradas:
  `logs/trinity/tdelibs-test-list.log`. No se afirma que todas estén probadas.
- MATE, logo y las ISO anteriores permanecen sin cambios.

## 2026-11-15 — tdelibs supera seis pruebas básicas

- `experiments/trinity/validate-tdelibs.sh` terminó con estado 0.
- tdecore, tdeui y tdeio resolvieron sus dependencias mediante `ldd`, sin
  mensajes de bibliotecas ausentes o errores de reubicación.
- Las seis pruebas seleccionadas de upstream pasaron: kcharsetstest,
  kglobaltest, kmacroexpandertest, krfcdatetest, kstringhandlertest y
  kurltest. CTest: 100 %, 0 fallos de 6.
- Registro completo: `logs/trinity/validation-tdelibs.log`.
- Conclusión limitada: tdelibs compila y supera esta selección básica en
  Alpine/musl. No se ha validado interfaz gráfica, sesión DCOP, hardware,
  audio, red del escritorio ni las otras pruebas declaradas.
- No se instaló tdelibs ni se construyó tdebase. El siguiente paso propuesto
  es instalar tdelibs en el laboratorio y probar la compilación de tdebase,
  previa autorización; no implica generar una ISO ni reemplazar MATE.
- Logo, configuración de lanzamiento e ISO anteriores sin cambios.

## 2026-11-15 — Prueba de tdebase autorizada; tdelibs instalado en laboratorio

- El usuario autorizó continuar con tdebase en el entorno aislado.
  No se autoriza aún sustituir MATE ni generar una ISO Trinity.
- Instalación de tdelibs completada con estado 0, exclusivamente en
  `/opt/trinity-experiment` del rootfs experimental.
- `tde-config --version`, `tde-config --prefix` y enlaces de tdecore
  comprobados con estado 0: `logs/trinity/tdelibs-installed.log`.
- Registro de instalación: `logs/trinity/install-tdelibs.log`.
- Descarga oficial de tdebase R14.1.7 iniciada en segundo plano y SHA-512
  publicado obtenido. Antes de extraer se verificará su integridad.
- Todavía no se eligieron opciones ni se compiló tdebase; se revisarán
  sus comprobaciones CMake actuales tras verificar las fuentes.
- MATE, logo, arranque y las ISO anteriores permanecen intactos.

## 2026-11-15 — Fuentes tdebase verificadas; compilación experimental iniciada

- SHA-512 de tdebase R14.1.7 verificado con el archivo oficial antes
  de extraer. Leídos CMakeLists.txt y ConfigureChecks.cmake actuales.
- Dependencias oficiales añadidas al laboratorio: libxkbfile-dev,
  libxtst-dev, libxdamage-dev, libxscrnsaver-dev, xkeyboard-config,
  xkeyboard-config-dev y linux-pam-dev.
- Se corrigió el nombre consultado libxss-dev por libxscrnsaver-dev:
  la primera transacción no instaló paquetes por ese nombre inexistente.
- Receta: `experiments/trinity/build-tdebase.sh`, CMake/Ninja Release,
  prefijo `/opt/trinity-experiment`, paralelismo 1.
- BUILD_ALL activado para los componentes del escritorio, excluyendo
  TDM y documentación. Se activan aRts, libart, tdehwlib, PAM y extensiones
  X11 disponibles (render, randr, cursor, xinerama, composite, fixes,
  test y screensaver). OpenGL queda desactivado por defecto, coherente
  con el TQt experimental sin OpenGL.
- Esto no define las funciones ni la autenticación de una futura ISO.
  No se instalan ni activan servicios del escritorio.
- Primer intento iniciado en segundo plano:
  `logs/trinity/build-tdebase-attempt1.log`. Resultado pendiente.
- MATE, logo, configuración de arranque e ISO anteriores sin cambios.

## 2026-11-15 — tdebase: ajuste de opción XScreenSaver

- Primer configure detenido porque WITH_XSCREENSAVER requiere los
  ejecutables externos y su directorio, además de libxscrnsaver.
  No llegó a compilar ni se considera un error de musl.
- Desactivada esa integración opcional en la receta experimental
  (`WITH_XSCREENSAVER=OFF`), evitando instalar programas adicionales
  ajenos a la prueba. No se cambia la configuración de la distribución.
- Segundo intento iniciado: `logs/trinity/build-tdebase-attempt2.log`.
  El primer registro se conserva. Resultado pendiente.

## 2026-11-15 — tdebase: dependencia RPC añadida

- Segundo configure detenido por ausencia de `rpc/rpc.h` al comprobar
  tdeioslave. No es necesario instalar glibc: Alpine ofrece libtirpc.
- Instalado `libtirpc-dev` y sus dependencias desde repositorios oficiales,
  solo en el rootfs experimental. Ningún servicio nuevo se activa.
- Registro APK: `logs/trinity/dependencies-tdebase-tirpc.log`; persiste
  el estado de error APK del laboratorio previamente documentado.
- Tercer intento iniciado con la misma receta, sin parches:
  `logs/trinity/build-tdebase-attempt3.log`. Resultado pendiente.
- MATE, logo, arranque e ISO anteriores sin cambios.

## 2026-11-15 — tdebase: generador RPC añadido

- Tercer configure avanzó tras añadir libtirpc y detectó otra herramienta
  necesaria para tdeioslave: `rpcgen`.
- Instalado rpcgen oficial (con dependencia rpcbind) únicamente en el
  laboratorio. No se arranca rpcbind ni se activa ningún servicio.
- Registro: `logs/trinity/dependencies-tdebase-rpcgen.log`.
- Cuarto intento en curso, sin parches ni más cambios de opciones:
  `logs/trinity/build-tdebase-attempt4.log`.

## 2026-11-15 — tdebase configurado; herramienta de fuentes añadida

- Cuarto intento superó CMake y comenzó 4152 tareas de construcción.
  Alcanzó la tarea 1149, tras enlazar libkonsolepart.so.
- Detención por herramienta ausente, no error C++: `bdftopcf`, requerida
  para convertir la fuente 9x15.bdf de Konsole al formato PCF.
- Instalado bdftopcf 1.1.2-r0 desde Alpine oficial, solo en el laboratorio.
  Registro: `logs/trinity/dependencies-tdebase-bdftopcf.log`.
- Quinto intento reanudado incrementalmente con la misma receta y sin
  parches: `logs/trinity/build-tdebase-attempt5.log`.
- Resultado pendiente. No se instala tdebase, no se inicia sesión gráfica
  y no se modifica MATE, el logo ni las ISO existentes.

## 2026-11-15 — tdebase compilado; binarios básicos comprobados

- Quinto intento terminado con estado 0. Finalizaron las 3000 tareas
  pendientes tras la reanudación. Registro:
  `logs/trinity/build-tdebase-attempt5.log`.
- No se aplicaron parches a las fuentes TQt/Trinity. Los bloqueos de esta
  etapa se resolvieron añadiendo herramientas oficiales de compilación
  y excluyendo la integración opcional con XScreenSaver.
- Receta de comprobación: `experiments/trinity/validate-tdebase.sh`,
  terminada con estado 0, sin instalar tdebase ni servidor gráfico.
- Twin, KDesktop, Kicker, Konsole y KSMServer son ejecutables ELF x86_64
  nativos de musl. Sus dependencias se resolvieron y cada `--version`
  terminó correctamente con un límite de 15 segundos.
- Versiones declaradas: TDE R14.1.7 y Konsole 1.6.6. Registro completo:
  `logs/trinity/validation-tdebase.log`.
- La configuración actual no declara pruebas CTest (`Total Tests: 0`).
  Las comprobaciones anteriores no equivalen a validar una sesión gráfica.
- Resultado acumulado: el toolkit, dependencias, bibliotecas centrales y
  componentes del escritorio se compilan en Alpine/musl sin parches.
- Pendiente, con autorización separada: instalar tdebase únicamente en el
  laboratorio y probar una sesión gráfica en servidor virtual aislado.
  No se afirma funcionamiento de red, audio, bloqueo, apagado o hardware.
- No se instaló tdebase, no se generó una ISO Trinity ni se sustituyó MATE.
  Logo, arranque e ISO existentes sin cambios.

## 2026-11-16 — Sesión gráfica experimental autorizada

- El usuario autorizó instalar tdebase y probar la sesión en el laboratorio.
- Instalación completada con estado 0: `logs/trinity/install-tdebase.log`.
- Añadidos Xvfb, D-Bus, fuentes DejaVu y herramientas X11 de diagnóstico
  desde Alpine oficial. No se activa ningún servicio del anfitrión.
- Entrada experimental ampliada con `--isolated-session`: namespaces de
  procesos y red propios, `/proc` propio de solo lectura y eliminación de
  procesos al terminar el namespace. No se expone la sesión X del anfitrión.
- Receta `experiments/trinity/test-graphical.sh`: display virtual :99,
  1280x800, sin escucha TCP, HOME/TDEHOME exclusivos del laboratorio
  y D-Bus de sesión privado. Primera personalización omitida solo en ese HOME.
- Se intenta iniciar starttde, detectar el gestor de ventanas, abrir Konsole,
  enviar texto y capturar pantalla/propiedades. Límite global: 180 segundos.
- Primer intento iniciado: `logs/trinity/test-graphical-attempt1.log`.
  No se declara éxito hasta revisar el resultado y la captura.
- MATE, logo, arranque e ISO existentes sin cambios.

## 2026-11-16 — Primer intento gráfico fallido; diagnóstico ampliado

- El primer intento no detectó gestor de ventanas dentro de 90 segundos
  y terminó con estado 1. No se declara una sesión Trinity funcional.
- El registro muestra fallo de ksplash, ausencia de bus D-Bus de sistema
  (no se inició en este laboratorio) y uso de `grep -Z`, no soportado
  por el grep de BusyBox instalado inicialmente.
- Añadidos GNU grep y xrdb oficiales solo al laboratorio.
- Definido TDEROOTHOME igual al TDEHOME de pruebas para que la sesión
  ejecutada como root del namespace no use el perfil separado /root/.trinity.
- Ampliada la receta para guardar propiedades X, árbol de ventanas,
  procesos y captura incluso al fallar. No se desactiva ksplash ni se
  parchea código para ocultar el cierre inesperado.
- Registros iniciales preservados como `session-attempt1.log` y
  `xvfb-attempt1.log` bajo `logs/trinity`.
- Segundo intento iniciado: `logs/trinity/test-graphical-attempt2.log`.
- No se modifica la distribución, el logo ni las ISO anteriores.

## 2026-11-16 — Segundo ensayo bloqueado por pantalla residual

- El segundo intento terminó antes de ejecutar starttde: Xvfb rechazó
  :99 por su bloqueo residual. El session.log seguía siendo del primer
  intento; no constituye evidencia de otro fallo de ksplash.
- Registro: `logs/trinity/test-graphical-attempt2.log` y
  `logs/trinity/xvfb-attempt2.log`.
- La receta ahora usa `Xvfb -displayfd` para escoger una pantalla libre
  y una salida controlada para terminar/esperar Xvfb antes de cerrar el
  namespace. No se borran bloqueos ni sockets de otras sesiones.
- Tercer ensayo iniciado: `logs/trinity/test-graphical-attempt3.log`.
  GNU grep y xrdb están instalados, pero aún falta evaluar su efecto real.
- Sesión gráfica todavía no validada; distribución e ISO sin cambios.

## 2026-11-16 — Fallo gráfico reproducible en KSplash

- El tercer ensayo abrió correctamente Xvfb, pero no llegó a Twin.
- Captura revisada: `logs/trinity/desktop-attempt3.png`, convertida desde
  XWD con `experiments/trinity/xwd-to-png.py`. Muestra el manejador de
  errores indicando SIGSEGV (señal 11) en KSplash.
- Procesos y árbol X confirman tdeinit/DCOP/tdelauncher/kded y drkonqi,
  pero no una sesión de escritorio completa. GNU grep ya no genera el
  error observado en el primer ensayo.
- Sigue ausente un bus D-Bus de sistema; no se atribuye sin evidencia
  a esa ausencia la causa del SIGSEGV.
- Instalado GDB oficial únicamente en el laboratorio. Añadido modo
  TDE_DEBUG_SPLASH para ejecutar KSplash sin fork bajo depurador,
  conservando el aislamiento de red, procesos y pantalla.
- Diagnóstico iniciado: `logs/trinity/ksplash-backtrace.log`.
  No se desactiva KSplash para declarar éxito artificialmente.
- Trinity gráfico no validado. MATE, logo e ISO permanecen intactos.

## 2026-11-16 — Diagnóstico KSplash: preparación de DCOP

- El primer ensayo GDB no produjo backtrace: KSplash quedó intentando
  adjuntarse a DCOP, a diferencia de la sesión completa que sí lo iniciaba.
  El estado 0 del comando no acredita ausencia de fallo ni diagnóstico útil.
- Añadido arranque de tdeinit al modo de depuración antes de GDB.
- Se activa solo loopback dentro del namespace de red privado, inicialmente
  desactivado por unshare. No se conecta ninguna interfaz externa.
- Segundo diagnóstico iniciado:
  `logs/trinity/ksplash-backtrace-attempt2.log`; salida de tdeinit en
  `logs/trinity/debug-tdeinit.log`.
- Se mantiene pendiente localizar la causa del SIGSEGV. Sin parches a
  Trinity, sin cambios de distribución ni nuevas ISO.

## 2026-11-16 — Depurador ajustado al namespace

- Segundo diagnóstico sin traza útil: GDB avisaba que no podía abrir
  `/proc/PID/mem` porque el proc privado estaba montado en solo lectura.
- Comprobado GDB con `/bin/true`, proc privado temporalmente escribible
  y `set startup-with-shell off`: informó salida normal del proceso.
- El modo TDE_DEBUG_SPLASH aplica ahora esos ajustes solo durante la
  depuración. No se remonta ni altera el `/proc` del anfitrión.
- Tercer diagnóstico iniciado en
  `logs/trinity/ksplash-backtrace-attempt3.log`, incluyendo `info program`
  y backtrace de todos los hilos.
- No hay todavía causa identificada del fallo de KSplash ni sesión
  gráfica validada. MATE, logo e ISO siguen sin cambios.

## 2026-11-16 — Diagnóstico gráfico inconcluso; no avanzar a ISO

- Ensayos GDB adicionales conservados en
  `logs/trinity/ksplash-backtrace-attempt3.log` a `attempt9.log`.
- GDB alcanza main y puede seguir fork; se añadió strace para distinguir
  ejecución real de falta de salida. Herramienta instalada solo en el lab.
- Con `--nofork` el proceso observado termina normalmente; siguiendo el
  hijo en el modo habitual se observó de nuevo el aviso de TDECrash.
  Esto es una diferencia de reproducción, no una causa demostrada.
- Ensayos con SIGSEGV explícitamente detenido, breakpoint en
  TDECrash::defaultCrashHandler y seguimiento de ambos procesos tampoco
  proporcionaron una pila útil del punto de fallo.
- El último ensayo conserva una pila del padre detenido en fork/_Fork,
  no del SIGSEGV; no debe presentarse como causa localizada en musl.
- Captura válida del bloqueo gráfico: `logs/trinity/desktop-attempt3.png`.
- Balance: compilación positiva, pero arranque gráfico estándar bloqueado
  y diagnóstico todavía inconcluso. No se valida Trinity como reemplazo
  de MATE ni se recomienda generar una ISO sobre esta evidencia.
- No se han aplicado parches a las fuentes ni desactivado KSplash.
  No queda ninguna prueba en segundo plano tras estos ensayos.
- MATE, logo, arranque e ISO anteriores permanecen sin cambios.

## 2026-11-17 — Arranque sin KSplash autorizado

- El usuario pidió probar explícitamente el escritorio sin KSplash.
- Añadido modo `TDE_NO_SPLASH=1` a la receta gráfica. Usa la opción
  soportada por starttde `ksplashrc: [KSplash] Theme=None`; no se parchean
  ni eliminan ejecutables.
- Perfil separado: `.work/trinity/graphical-home-no-splash`; los perfiles
  y evidencias anteriores se conservan.
- Evidencias de esta prueba en `logs/trinity/no-splash/`.
- Se exige detectar gestor de ventanas, abrir una ventana Konsole visible
  y ejecutar mediante teclado un comando que escriba `input-proof.txt`.
  El script comprueba el contenido; una ventana abierta por sí sola no
  se considera prueba de entrada funcional.
- Ensayo iniciado en namespace de red/procesos con Xvfb y D-Bus privado,
  límite de 180 segundos. Registro:
  `logs/trinity/test-no-splash-attempt1.log`.
- Resultado y revisión visual pendientes. No se declara corregido KSplash
  aunque este ensayo llegase a funcionar.
- MATE, logo, arranque e ISO existentes permanecen intactos.

## 2026-11-17 — Escritorio Trinity iniciado sin KSplash

- Ensayo `test-no-splash-attempt1.log` terminado con estado 0.
- Captura `logs/trinity/no-splash/desktop.png` revisada: escritorio Trinity,
  panel inferior Kicker, decoraciones Twin, Konsole y ventana de consejos
  KTip visibles. No aparece el diálogo de fallo de KSplash.
- Procesos registrados: KSMServer, Twin, KDesktop, Kicker y Konsole,
  además de DCOP y componentes de sesión. No basta por sí solo su presencia;
  se confirmó visualmente el escritorio y se probó entrada de teclado.
- El comando escrito con xdotool en Konsole produjo `input-proof.txt`
  con el contenido exacto `MABOS_TRINITY_INPUT_OK`.
- Evidencias en `logs/trinity/no-splash/`, incluidos árbol X, propiedades
  de raíz, procesos y salida de sesión.
- Persisten advertencias: falta bus D-Bus de sistema, llamada a /bin/awk
  inexistente y rutas de zona horaria, además de funciones no disponibles
  en Xvfb (DPMS/touchpad). No se validan audio, energía, red o hardware.
- Los errores X11 al terminar corresponden al cierre del servidor virtual
  al finalizar la receta; no se cuentan como prueba de apagado normal.
- Conclusión: arranque gráfico básico viable sin KSplash; no se considera
  corregido su SIGSEGV ni demostrado que sea el único problema.
- Iniciado ensayo adicional `TDE_EXTENDED_DESKTOP=1` para mover,
  redimensionar, minimizar/restaurar Konsole y capturar el menú.
  Registro `logs/trinity/test-no-splash-extended.log`; evidencias separadas
  en `logs/trinity/no-splash-extended/`. Resultado pendiente.
- MATE, logo, arranque e ISO permanecen sin cambios.

## 2026-11-17 — Prueba ampliada sin KSplash superada

- Ensayo `logs/trinity/test-no-splash-extended.log` terminado con estado 0.
- Capturas revisadas en `logs/trinity/no-splash-extended/desktop.png`
  y `menu.png`: escritorio, iconos, panel Kicker y menú de aplicaciones
  visibles; Konsole restaurada y redimensionada.
- Verificado por xdotool: área de Konsole 900x500 y desplazamiento aplicado.
  Minimización confirmada por `_NET_WM_STATE_HIDDEN`; después se restauró
  la ventana y se activó correctamente.
- Entrada por teclado comprobada nuevamente mediante el archivo de prueba.
  Alt+F1 abrió el menú y Escape lo cerró, confirmado en las capturas.
- El panel muestra «KNotify Problem»; no se considera validado el sistema
  de notificaciones/sonido. Persisten las limitaciones del laboratorio
  anotadas antes, incluido el bus D-Bus de sistema ausente.
- Conclusión: el escritorio básico y la gestión de ventanas funcionan en
  esta prueba Xvfb sin KSplash. No demuestra estabilidad prolongada,
  funcionamiento como usuario live, red, audio, energía o hardware real.
- KSplash sigue sin corregir; Theme=None es una exclusión explícitamente
  autorizada para investigar el resto del escritorio, no una solución del bug.
- No quedan ensayos activos. MATE, logo, arranque e ISO anteriores
  permanecen sin cambios; no se generó una ISO Trinity.

## 2026-11-17 — Pruebas mínimas previas a ISO autorizadas

- El usuario autorizó probar usuario live, D-Bus, red, audio y salida de
  sesión antes de plantear una ISO Trinity.
- El namespace actual solo mapea un UID y no hay newuidmap/newgidmap
  disponibles. No permite comprobar separación real root/live/usuario D-Bus.
- Se elige VM temporal con disco experimental propio, sin dispositivos
  físicos conectados y sin generar una ISO. QEMU ya está disponible en
  el Alpine de herramientas; no se cambian sus scripts ni paquetes.
- Iniciada instalación de kernel y herramientas VM solo en rootfs Trinity,
  con PulseAudio, utilidades ALSA, D-Bus, curl, certificados y tzdata.
  La descarga inicial excedió el límite de 120 segundos; se reanudó en
  segundo plano. Registros `dependencies-vm.log` y
  `dependencies-vm-resume.log` bajo `logs/trinity/`.
- Recetas preparadas en `experiments/trinity/`: prepare-vm.sh,
  create-vm-disk.sh, run-vm.sh, vm-init.sh y vm-session.sh.
- Se comprobará usuario UID 1000, D-Bus de sistema y sesión, HTTPS,
  flujo de audio hacia tarjeta emulada y cierre de sesión vía KSMServer.
- El audio emulado con backend nulo no acredita sonido audible.
  Wi-Fi/hardware y apagado/reinicio físico no se validan en este entorno.
- Los resultados todavía están pendientes: la VM no se ha creado ni
  arrancado. MATE, logo e ISO existentes siguen intactos.

## 2026-11-17 — Kernel de VM preparado; disco temporal en construcción

- Finalizó instalación de dependencias VM. APK conserva los dos errores
  de propietarios del namespace; kernel/herramientas quedaron instalados.
- `prepare-vm.sh` terminó con estado 0: kernel 6.18.63-0-lts e initramfs
  con base, virtio y ext4 preparados en `.work/trinity/vm/`.
- Scripts de inicio y prueba copiados solo al rootfs Trinity experimental.
- `create-vm-disk.sh` iniciado en segundo plano. Genera ext4 con copia
  del rootfs y propietarios root mapeados correctamente. No usa discos
  físicos, no monta imágenes del usuario ni sobrescribe una imagen existente.
- Registros: `logs/trinity/prepare-vm.log` y
  `logs/trinity/create-vm-disk.log`.
- La VM aún no se ha arrancado; pruebas funcionales pendientes.

## 2026-11-17 — Primera prueba de VM iniciada

- Disco ext4 temporal creado con estado 0; las ISO no se utilizan ni cambian.
- Iniciado QEMU/KVM con 1536 MiB, dos vCPU, disco propio, red de usuario
  y tarjeta HDA emulada con salida de audio nula.
- No se conectan discos ni dispositivos de audio físicos.
- Registro de consola: `logs/trinity/vm-attempt1.serial.log`.
- Preparado `extract-vm-results.sh` para recuperar logs/captura mediante
  debugfs de solo lectura, únicamente después de detener QEMU.
- Pendientes los resultados del arranque y pruebas; no se declara éxito
  por el mero inicio del proceso QEMU.

## 2026-11-17 — VM arranca; guion DHCP corregido

- Primera VM alcanzó el inicio propio y respondió ListNames en D-Bus de
  sistema. No llegó a la sesión live.
- DHCP quedó repitiendo «Network is down» porque el guion no activaba
  eth0 antes de udhcpc. QEMU terminó al alcanzar el límite externo.
- Corregido `vm-init.sh`: eth0 se activa y DHCP tiene límite de 30 segundos.
  Añadido grupo plugdev del laboratorio para la configuración D-Bus.
- Actualizados solo los dos guiones del disco temporal propio mediante
  `update-vm-scripts.sh`, con QEMU detenido. No se toca ninguna ISO.
- Segundo ensayo iniciado: `logs/trinity/vm-attempt2.serial.log`.
- Resultados de usuario live, audio y escritorio todavía pendientes.

## 2026-11-17 — VM: HTTPS y tarjeta detectados; raíz escribible pendiente

- Segundo ensayo obtuvo DHCP 10.0.2.15, ruta y respuesta HTTPS de Alpine
  (`MABOS_HTTPS_OK`). D-Bus de sistema respondió y ALSA detectó HDA Intel.
- El initramfs dejó la raíz ext4 montada en solo lectura. Al usar un PID 1
  de prueba propio faltaba el remontaje que haría el arranque normal.
  Falló crear live: `su: unknown user live`. No se validó aún esa sesión.
- El guion ahora remonta `/` escribible únicamente dentro de la VM.
  Se actualizó el disco temporal con QEMU detenido.
- Apagado forzado del kernel de la VM completado; esto no prueba el
  apagado desde el menú de Trinity.
- Tercer ensayo iniciado: `logs/trinity/vm-attempt3.serial.log`.
- MATE, logo, configuración de arranque de MabOs e ISO sin cambios.

## 2026-11-17 — VM: live y D-Bus comprobados; ajustes de caché/audio

- Tercer ensayo confirmó UID/GID 1000 live, grupos audio/video y consulta
  de D-Bus de sistema desde live. DHCP/HTTPS volvieron a responder.
- Sesión detenida antes de Twin: lnusertemp no pudo crear
  `/var/tmp/tdecache-live` por permisos del directorio en el rootfs copiado.
- Corregidos solo en el inicio de la VM los permisos 1777 de /var/tmp
  y los directorios de sockets X11/ICE, equivalentes a temporales compartidos.
- PulseAudio se inició, pero solo descubrió auto_null. La marca inicial
  AUDIO_STREAM_OK acreditaba flujo nulo, no audio hacia HDA emulada.
- La receta ahora carga module-alsa-sink para hw:0,0, exige vm_hda en
  la lista de salidas y dirige allí el flujo PCM. Sigue sin probar audibilidad.
- Evidencias del tercer ensayo preservadas en
  `logs/trinity/vm-results-attempt3/`.
- Cuarto ensayo en curso: `logs/trinity/vm-attempt4.serial.log`.
- Escritorio live, KNotify y salida de sesión todavía pendientes.

## 2026-11-17 — Diario del disco temporal recuperado antes de actualizar

- Cuarto ensayo repitió el guion anterior (salida auto_null y sesión sin
  escritorio), por lo que no valida los ajustes previstos.
- debugfs detectó inconsistencia de checksum al abrir el disco detenido.
  Se conservó copia dispersa `test-root-before-fsck.ext4`, solo del disco
  de laboratorio, antes de repararlo.
- e2fsck -f -p recuperó el diario y terminó con estado 1 (correcciones).
  Los apagados forzados dejan el diario pendiente; modificar offline sin
  reproducirlo puede hacer que el siguiente arranque reponga datos antiguos.
- update-vm-scripts.sh ahora exige e2fsck previo y aborta si el estado es
  mayor que 1. No opera sobre discos físicos ni ISO.
- Verificado por lectura directa del disco que el guion instalado incluye
  vm_hda y module-alsa-sink: `vm-installed-session-script.txt`.
- Quinto ensayo iniciado: `logs/trinity/vm-attempt5.serial.log`.
- Usuario live y conectividad tienen evidencia previa; escritorio live,
  flujo HDA y cierre de sesión siguen pendientes.

## 2026-11-17 — VM: escritorio live, HTTPS, audio emulado y logout positivos

- Quinto ensayo completó escritorio como UID 1000, teclado en Konsole,
  flujo PCM a vm_hda (module-alsa-sink, hw:0,0) y salida normal de
  sesión vía `dcop ksmserver ksmserver logout 0 0 0`.
- Captura revisada: escritorio/panel/terminal como live, sin KSplash ni
  ventana «KNotify Problem». Resultados preservados en
  `logs/trinity/vm-results-attempt5/`.
- Quedaba denegada la activación D-Bus del control de hardware porque
  el paquete no pudo conservar el grupo del ayudante setuid en el
  namespace de compilación. Se restauró dentro de la VM el propietario
  root:messagebus y modo 4750 de dbus-daemon-launch-helper.
- Sexto ensayo completado: `logs/trinity/vm-attempt6.serial.log`.
  Confirmados MABOS_LIVE_HTTPS_OK, AUDIO_STREAM_OK, LIVE_DESKTOP_READY,
  LIVE_KEYBOARD_OK, LOGOUT_OK y SESSION_RESULT=0.
- HTTPS probado ahora desde live además de root. UID escrito en Konsole:
  1000. D-Bus de sistema consultado por live y D-Bus de sesión privado
  disponible. No reapareció el error de activación por permisos.
- KNotify registra su cliente DCOP y responde con su interfaz de métodos;
  no se afirma probado cada evento/notificación o su sonido.
- Captura final y datos: `logs/trinity/vm-results/desktop.png`,
  pulse-sinks.txt, typed-uid.txt, knotify-interface.txt y session.log.
- Se observan avisos BadWindow durante salida de sesión; no impidieron
  que KSMServer/starttde terminaran con estado 0.
- Límites: audio hacia HDA emulada con backend nulo, no audibilidad real.
  No se probó Wi-Fi ni hardware físico, ni Firefox/AbiWord integrados.
  La VM usa un PID 1 de pruebas propio, no el arranque OpenRC de la ISO.
- El apagado posterior mediante poweroff -f es solo limpieza de VM.
  Reinicio y apagado solicitados desde el escritorio siguen pendientes;
  estos resultados NO validan aún esa integración.
- Sin pruebas en segundo plano. 18 pruebas automatizadas del proyecto
  pasaron nuevamente. MATE, logo, arranque e ISO anteriores sin cambios.
- No se generó una ISO Trinity. KSplash continúa excluido solo en el lab.

## 2026-11-17 — ISO Trinity experimental autorizada; empaquetado en curso

- El usuario pidió generar la ISO tras las pruebas. Se prepara una imagen
  separada `0.1.0-trinity1`, sin KSplash; no reemplaza alpha3 con MATE.
- Se mantienen explícitamente pendientes reinicio/apagado desde Trinity
  y validaciones de hardware real. No se presenta como versión estable.
- No se aplica el cambio de logo a cactus. El arte principal permanece
  intacto; se rasterizó el mismo SVG Oasis para el fondo del nuevo escritorio.
- Bundle APK local: `experiments/trinity/packaging/APKBUILD` y
  `package-trinity.sh`. Usa los binarios ya compilados y dos archivos de
  activación D-Bus instalados fuera de /opt.
- El bundle declara sus prefijos /opt y ayudantes SUID de upstream de
  forma explícita a abuild (!fhs, suid); no se desactivan firmas.
  Añade rutas musl para que los servicios D-Bus resuelvan sus bibliotecas.
- Primeros intentos de abuild detectaron entorno Git sin commits, prefijos
  no estándar, strip ausente y bibliotecas externas no instaladas en el
  empaquetador. Se usa staging fuera de Git, se instaló binutils y se
  calculan dependencias ELF externas antes de generar metadatos APK.
- No se aplican parches a las fuentes Trinity. El strip afecta solo a
  copias del paquete, no a los binarios originales del laboratorio.
- Ensayo de empaquetado activo: `logs/trinity/package-trinity-attempt6.log`.
- Entradas de ISO separadas preparadas en `experiments/trinity/iso-overlay`
  y generador `prepare-iso.py`. La receta principal de MATE no se modifica.
- La selección prevista retira el escritorio MATE, conservando mate-themes
  y mate-polkit como tema GTK y agente de autorización, no sesión MATE.
  Conserva Firefox, AbiWord, red, audio y aplicaciones ya seleccionadas.
- Se usará LightDM con autologin live, paquete Trinity firmado y repositorios
  Alpine oficiales más el repositorio propio local del bundle.
- La ISO todavía no está construida. Debe verificarse y arrancarse en VM
  antes de declararla lista para pruebas físicas.

## 2026-11-17 — APK Trinity firmado; construcción de ISO iniciada

- Empaquetado finalizado con estado 0:
  `logs/trinity/package-trinity-attempt6.log`.
- Bundle instalado ocupa 187.8 MB según abuild. Se generaron APK e índice
  de repositorio firmados con la clave de construcción MabOs existente.
- Las dependencias externas se calcularon por SONAME; no se incluyen
  bibliotecas del laboratorio como sustitutos de las oficiales Alpine.
- Creado proyecto de construcción separado en
  `.work/trinity/iso-project`, con versión `0.1.0-trinity1`.
- Configuración global sigue en alpha3; no se edita su selección MATE.
  El constructor experimental usa su propio rootfs y directorio de trabajo.
- Configurada sesión LightDM mabos-trinity con autologin live, KSplash
  None, PulseAudio/nm-applet y agente de autorización conservado.
- Fondo Oasis rasterizado del SVG original para Trinity. Logo de diente
  de león conservado; no se aplicó el pendiente de cactus.
- Iniciada construcción mediante la copia separada de scripts/build.sh.
  Registro: `logs/trinity/iso-build-attempt1.log`.
- Pendientes artefacto, checksum, comprobación BIOS/UEFI y revisión gráfica.
  No se declara la ISO lista ni se sobrescriben las imágenes anteriores.

## 2026-11-17 — ISO trinity1 generada; arranque final en validación

- Construcción finalizada con estado 0:
  `logs/trinity/iso-build-attempt1.log`.
- Imagen: `dist/mabos-0.1.0-trinity1-x86_64.iso`,
  944 766 976 bytes (901 MiB aproximadamente).
- Comprobación de checksum, estructura híbrida BIOS/UEFI, overlay e
  índice de paquetes pasada: `logs/trinity/iso-check.log`.
  Manifiesto de 593 paquetes conservado junto a la imagen.
- Copiados al dist principal únicamente archivos nuevos de trinity1,
  con comprobación explícita de no sobrescribir archivos existentes.
- SHA-256 de alpha1, alpha2, alpha3 y trinity1 comprobados: coinciden.
- Iniciadas pruebas secuenciales BIOS y UEFI con 3072 MiB, sin discos
  físicos conectados. Evidencias previstas: `logs/trinity1-bios*` y
  `logs/trinity1-uefi*`.
- No se declara lista hasta revisar sus capturas de escritorio.
  Las pruebas anteriores del laboratorio no sustituyen probar esta ISO.

## 2026-11-17 — trinity1 falla el escritorio; revisión de empaquetado iniciada

- Revisadas ambas capturas finales. BIOS y UEFI arrancan el medio, pero
  Twin muestra SIGSEGV. UEFI también muestra errores al cargar tdeio_file
  y el applet de paginador. El escritorio NO queda validado.
- Evidencias: `logs/trinity1-bios.png` y `logs/trinity1-uefi.png`.
- La imagen `dist/mabos-0.1.0-trinity1-x86_64.iso` se conserva como
  artefacto FALLIDO de laboratorio; no se recomienda para uso físico.
- Se comprobó una diferencia entre laboratorio y bundle: abuild elimina
  por defecto los archivos .la salvo opción libtool. El APK r0 contiene
  cero .la, mientras Trinity usa módulos cargados mediante libtool/ltdl.
- Se añade opción libtool y se incrementa pkgrel a 1 para conservarlos.
  Es una corrección de empaquetado, no un parche al código Trinity.
- Todavía no se atribuye con certeza todo el SIGSEGV a esta diferencia:
  la revisión deberá comprobarse con otro arranque real.
- Empaquetado r1 iniciado: `logs/trinity/package-trinity-r1.log`.
- prepare-iso.py permite un proyecto/versión separados trinity2, para
  conservar trinity1 y sus sumas sin sobrescribirlos.
- No se modifican MATE, logo ni las ISO alpha anteriores.

## 2026-11-17 — Bundle r1 verificado; ISO trinity2 en construcción

- Bundle r1 terminado y verificado con `apk verify`: OK.
- Confirmados 392 archivos .la en el APK, frente a cero en r0.
- Proyecto separado creado en `.work/trinity/iso-project-trinity2`,
  versión `0.1.0-trinity2`. Conserva la misma selección y configuración
  experimental; la diferencia es la revisión de empaquetado.
- Construcción iniciada: `logs/trinity/iso-build-trinity2.log`.
- No se sobrescribe trinity1 ni las imágenes alpha. Pendiente comprobar
  si la revisión resuelve realmente los errores de carga y Twin.

## 2026-11-18 — Trinity2 comprobada en BIOS y UEFI

- Confirmado que la construcción terminó y pasó la revisión de estructura
  y manifiesto de 593 paquetes. SHA-256 verificado nuevamente:
  `87d7acb7f86be50ab6ab651d5dba2beab9bc7e2b2bb691be4e0f17a7682dbb9e`.
- ISO en `.work/trinity/iso-project-trinity2/dist/`; aún no copiada al
  directorio dist principal.
- Pruebas QEMU/KVM BIOS y UEFI con 3072 MiB y 2 vCPU. Escritorio completo,
  fondo Oasis, iconos y panel revisados en capturas. Procesos twin,
  kicker, kdesktop y Konsole ejecutándose como live en ambas pruebas.
- Konsole recibió y ejecutó un diagnóstico, AbiWord recibió texto y
  Firefox abrió https://alpinelinux.org en ambos modos. HTTPS también
  confirmó `internet-ok` mediante wget ejecutado con doas.
- Evidencias: `logs/trinity2-bios-apps*` y `logs/trinity2-uefi-apps*`.
  No aparecieron los diálogos de SIGSEGV de Twin ni los errores de carga
  observados en trinity1 durante estas pruebas. La revisión r1 con los
  archivos .la supera esta comprobación básica del escritorio.
- La primera captura BIOS fue demasiado temprana y solo mostró el panel.
  La primera captura UEFI a los 90 segundos seguía cargando paquetes.
  Se repitieron con espera hasta getty y revisión de escritorio/aplicaciones.
- Para estas pruebas se adaptó temporalmente scripts/test-vm.py en
  `.work/test-trinity-session.py`, usando Konsole y un diagnóstico sin
  consultas específicas de MATE. El guion principal conserva su contenido.
- Detalles pendientes observados: textos de Trinity en inglés, KTip
  aparece al iniciar y el saludo serie todavía menciona MATE.
- Pendientes reinicio y apagado desde Trinity, audio de esta ISO,
  Ventoy y hardware físico. Estas pruebas terminan mediante QMP quit.
  Todas las VM de esta comprobación finalizaron.

## 2026-11-18 — Trinity2 disponible en dist

- Copiados los cinco artefactos trinity2 al directorio `dist` principal,
  incluyendo ISO, sumas, manifiesto y datos de construcción.
- Imagen para la siguiente prueba con Ventoy:
  `dist/mabos-0.1.0-trinity2-x86_64.iso`.
- Continúan pendientes las comprobaciones físicas y de energía descritas
  en la entrada anterior. Imagen experimental.

## Referencia

El plan inicial está en `/home/mt/.opencode/plan/alpine-mate.md`.
Este documento es el registro de implementación dentro del proyecto.
