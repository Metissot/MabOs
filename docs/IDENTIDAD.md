# MabOs Oasis

## Dirección visual

Un escritorio tranquilo, ligero y cercano. Poco ruido visual, colores suaves,
texto legible y herramientas reconocibles.

| Papel | Color |
|---|---|
| Verde del paisaje | `#355e50` |
| Verde salvia | `#9eb4a1` |
| Arena | `#ddcfb1` |
| Cielo suave | `#d5e5df` |
| Blanco cálido | `#f1eadb` |

- Fondo original: `overlay/etc/mabos/artwork/oasis.svg`.
- Icono original: `overlay/etc/mabos/artwork/dandelion.svg`.
- Logotipo: `overlay/etc/mabos/artwork/mabos-wordmark.svg`, con la O formada
  por un diente de león y semillas al viento, por referencia del usuario a Catamarca.
- Iconos: **Papirus-Light**, incluido en el paquete oficial papirus-icon-theme.
- Controles y ventanas: **YaruOk**, incluido en mate-themes.
- Tipografía: DejaVu Sans; terminal con DejaVu Sans Mono.
- Aplicaciones: cactus junto al texto; se conserva el menú familiar de MATE.
- Acceso gráfico: fondo conservado, logotipo de diente de león y YaruOk.
- Panel único superior: menú, lista de ventanas, indicadores y reloj.
  El panel inferior y sus otros elementos no se trasladan.

El fondo no fue modificado: mantiene el paisaje Oasis, incluido el cactus
del paisaje. La sustitución solicitada afecta al logo, no al fondo.

El diente de león se instala como `mabos-logo` en hicolor y se selecciona mediante
la preferencia de MATE. No se sobrescribe el icono global `start-here` de
Papirus ni se alteran otros logotipos.

## Configuración

- Preferencias modificables por el usuario:
  `overlay/etc/dconf/db/mabos.d/00-desktop`.
- Pantalla de acceso:
  `overlay/etc/lightdm/lightdm-gtk-greeter.conf`.
- Bienvenida bajo demanda:
  `overlay/etc/mabos/mabos-welcome`.
- Versión común para scripts y pantallas: `config/version`.
- Panel MATE: `overlay/etc/mabos/mabos.layout`, instalado antes de la sesión.

La bienvenida da acceso a red, teclado, apariencia y guía. No se abre
automáticamente: queremos evitar trabajo adicional durante el arranque.

Los SVG originales se ofrecen bajo CC0 1.0. Papirus mantiene su propia
licencia GPL-3.0; el tema MATE y las demás aplicaciones conservan sus licencias.
No se modifica la identidad de Alpine como base: os-release conserva ID_LIKE.

El cambio de cactus a diente de león, YaruOk, Papirus-Light y panel único
fue solicitado expresamente por el usuario para alpha3. No es un rediseño
general ni una autorización para modificar otros componentes.

## Límites de esta iteración

- No añadir dock, compositor extra ni animación de arranque.
- No forzar preferencias con bloqueos de dconf.
- No instalar todas las traducciones o componentes opcionales a ciegas.
- Firefox ESR en Alpine no ofrece un paquete español con el nombre que
  habíamos previsto; `firefox-esr-intl` solo incorpora datos ICU, no traduce
  la interfaz. No se instalará fingiendo que resuelve el idioma.
- Revisar el resultado real en una VM y después en hardware.
