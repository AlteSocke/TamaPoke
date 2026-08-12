#!/bin/bash
# Regenera web/firmware/*.bin para el instalador web.
# Uso: bash tools/build_web.sh
#
# IMPORTANTE: se copian 4 archivos SUELTOS (bootloader/partitions/boot_app0/app),
# cada uno a su propio offset en manifest.json -- NO se fusionan en un solo
# binario. La particion NVS (donde vive el guardado del bicho: prefs.begin
# ("tamapoke",...) en pet.cpp) esta en el hueco 0x9000-0xE000, entre el final
# de partitions.bin (~0x8C00) y el inicio de boot_app0.bin (0xE000). Un merge-bin
# clasico rellena ese hueco con 0xFF y lo mete en el binario final; al escribir
# ese rango a la flash, esptool BORRA el sector primero (asi funciona la NOR
# flash), lo que resetea el guardado en CADA actualizacion -- pase lo que pase
# con la casilla "Erase device" del instalador web. Con partes sueltas, ESP Web
# Tools nunca escribe en ese hueco, y el guardado sobrevive a las actualizaciones
# normales (solo se pierde si el usuario marca "Erase device").
set -e
cd "$(dirname "$0")/.."
FQBN="esp32:esp32:esp32s3:CDCOnBoot=cdc,FlashSize=16M,PSRAM=opi,PartitionScheme=app3M_fat9M_16MB"

echo "Compilando..."
arduino-cli compile --fqbn "$FQBN" --export-binaries .

B=build/esp32.esp32.esp32s3
echo "Copiando binarios sueltos (sin fusionar, para no pisar la particion NVS)..."
cp "$B/TamaPoke.ino.bootloader.bin" web/firmware/bootloader.bin
cp "$B/TamaPoke.ino.partitions.bin" web/firmware/partitions.bin
cp "$B/boot_app0.bin"               web/firmware/boot_app0.bin
cp "$B/TamaPoke.ino.bin"            web/firmware/app.bin

echo "OK -> web/firmware/{bootloader,partitions,boot_app0,app}.bin"

echo "Empaquetando sprites..."
python3 tools/pack_bundle.py
