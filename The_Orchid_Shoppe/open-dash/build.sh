#!/bin/bash
# ==============================================
# Build Script: Cyber Dash Launcher
# Author: Jason Santiago
# Location: /mnt/c/Users/jasdi/Desktop/DashboardLauncher
# ==============================================

# Stop the script if any command fails
set -e

# --- Variables ---
SRC="open_dash.c"              # Main C source file
OUT="open-dash.exe"            # Output executable name
RC_FILE="icon.rc"              # Resource script for icon
RC_OBJ="icon.o"                # Compiled resource object
ICON_PATH="./assets/app.ico"   # Path to your .ico file
DESKTOP_PATH="C:/Users/jasdi/Desktop"  # Output directory

# --- Check Output Path ---
if [ ! -d "$DESKTOP_PATH" ]; then
    echo "[!] Output path not found: $DESKTOP_PATH"
    echo "[!] Please create the folder or update the DESKTOP_PATH variable."
    exit 1
fi

# --- Compile Icon Resource ---
echo "[*] Compiling icon resource..."
x86_64-w64-mingw32-windres "$RC_FILE" -O coff -o "$RC_OBJ"

# --- Build Executable ---
echo "[*] Building $OUT ..."
x86_64-w64-mingw32-gcc "$SRC" "$RC_OBJ" -o "$OUT" -mwindows -Wall

# --- Copy Executable to Desktop Path ---
echo "[*] Copying $OUT to configured path..."
cp "$OUT" "$DESKTOP_PATH/"

# --- Completion Message ---
echo "[+] Done! EXE is in $DESKTOP_PATH"
