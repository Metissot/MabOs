#!/bin/sh
# Solo para el anfitrión de compilación: scanelf se bloquea con esta versión
# de libfakeroot. Leer ELF no requiere simular propietarios.
unset LD_PRELOAD FAKEROOTKEY
exec /usr/bin/scanelf "$@"
