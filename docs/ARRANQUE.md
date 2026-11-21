# Investigación del arranque live

## Lo que sabemos

El usuario confirmó que alpha1 funciona en su PC y reportó una espera larga.
Todavía no hay cronometraje ni registros de ese equipo físico.

La imagen alpha1:

- Lee un initramfs de aproximadamente **172 MiB**, con KMS y firmware gráfico.
- Instala unos **634 paquetes** en RAM durante cada arranque.
- Lee y verifica un modloop de aproximadamente **290 MiB**.
- Inicia OpenRC, los servicios de sesión y MATE.

El tamaño del initramfs está medido. Atribuir todo el tiempo de arranque a una
sola etapa sin medir sería una suposición.

## Cambio para alpha2

Quitar la característica `kms` del initramfs, manteniendo el kernel, Mesa,
los módulos gráficos y el firmware en modloop. Udev debe detectar y cargar
esos módulos antes de LightDM.

Esto reduce el trabajo inicial, pero puede retrasar el cambio a la resolución
nativa hasta que arranque udev. Hay que comprobar la imagen en GPU reales;
si un equipo requiere gráficos tempranos, conservar alpha1 como alternativa.

No se desactivan firmas, microcódigo, firmware ni servicios de seguridad.
No se pretende acelerar ocultando los errores.

### Tamaños observados al compilar

| Archivo | Alpha1 | Alpha2 |
|---|---:|---:|
| Initramfs | 179 926 528 bytes (171.6 MiB) | 22 542 320 bytes (21.5 MiB) |
| ISO | 1 025 507 328 bytes (978 MiB) | 907 018 240 bytes (865 MiB) |

El initramfs se redujo aproximadamente un 87.5%, conservando los controladores
en modloop. Esto **no significa** que el tiempo total de arranque mejore un
87.5%: siguen pendientes la instalación de paquetes y los demás pasos.

## Cómo medimos

`scripts/test-vm.py` escribe un archivo `logs/ETIQUETA.timing.json` con:

- ISO y SHA-256.
- Firmware, RAM y número de CPU virtuales.
- Segundos desde lanzar QEMU hasta el prompt de getty posterior a OpenRC.
- Segundos hasta la captura gráfica.

El prompt **no equivale** al instante exacto en que aparece MATE. La captura
se revisa por separado. La medida incluye preparación del entorno y QEMU.

Ejemplo:

```sh
python3 scripts/test-vm.py uefi \
  --iso dist/mabos-0.1.0-alpha1-x86_64.iso \
  --label comparacion-alpha1-uefi --memory 3072 --seconds 300
python3 scripts/test-vm.py uefi \
  --iso dist/mabos-0.1.0-alpha2-x86_64.iso \
  --label comparacion-alpha2-uefi --memory 3072 --seconds 300
```

Ejecutar una VM a la vez, sin compilar ni otras cargas pesadas. Idealmente,
repetir cada medición varias veces. La caché de archivos y el estado del
anfitrión afectan los resultados. No extrapolar los segundos virtuales al USB.

La primera medición de alpha1 dio 124.49 s hasta getty, pero coincidió
parcialmente con la construcción de alpha2. Es **exploratoria**, no una
comparación controlada ni una garantía de rendimiento.

### Resultados de esta iteración

Sin compilación concurrente, KVM, dos CPU virtuales y 3072 MiB:

| Imagen | Firmware | Tiempo hasta getty | Evidencia |
|---|---|---:|---|
| Alpha1 | UEFI | 109.38 s | `logs/comparacion-alpha1-uefi.timing.json` |
| Alpha2 final | UEFI | 86.34 s | `logs/oasis-release-uefi.timing.json` |
| Alpha2 final | BIOS | 60.48 s | `logs/oasis-release-bios.timing.json` |

La observación UEFI final fue aproximadamente **21% menor** que la de alpha1.
Es una comparación de muestras individuales, no una media estadística.
La carga del anfitrión y sus cachés pueden influir; no atribuir toda la
diferencia a un único cambio ni prometer ese porcentaje en hardware real.

La imagen actual contiene además Papirus, que añade unos 114 MiB de archivos
de iconos y metadatos en RAM. Una ISO más pequeña no implica necesariamente
menor consumo de memoria del escritorio. Se mantiene la recomendación
provisional de al menos 4 GiB para pruebas cómodas.

El arranque sigue instalando paquetes en RAM; la optimización del initramfs
mejora una etapa, pero no elimina ese trabajo.

## Prueba en USB real

Cronometrar desde elegir MabOs en el menú de arranque hasta:

1. Aparición de los mensajes iniciales.
2. Fin de preparación de paquetes.
3. Fin de verificación de modloop.
4. Aparición del escritorio utilizable.

Anotar RAM, GPU, modo BIOS/UEFI, modelo del USB y puerto utilizado. Repetir
con el mismo equipo y USB antes de afirmar que una versión es más rápida.
La entrada de diagnóstico muestra más detalles sin desactivar verificaciones.

## Siguiente optimización si sigue siendo lento

Evaluar un sistema live **preinstalado en SquashFS con una capa temporal de
escritura**, para no reinstalar cientos de paquetes en cada arranque.
Es un cambio mayor del mecanismo live y requiere pruebas de permisos,
actualizaciones, montaje, integridad y recuperación; no se introduce a ciegas
en esta primera mejora visual.
