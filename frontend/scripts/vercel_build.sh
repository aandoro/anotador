#!/usr/bin/env bash
# Build de Flutter Web para Vercel.
# API_BASE_URL debe configurarse en el panel de Vercel (Environment Variables).
set -euo pipefail

FLUTTER_SDK="${FLUTTER_SDK_PATH:-$HOME/flutter}"

if [ -z "${API_BASE_URL:-}" ]; then
  echo "ERROR: API_BASE_URL no está definida."
  echo "Configurala en Vercel → Project Settings → Environment Variables"
  echo "con la URL pública del backend en Render (ej. https://mio-backend.onrender.com)."
  exit 1
fi

# Normaliza barra final para evitar doble slash en los endpoints.
API_BASE_URL="${API_BASE_URL%/}"

if [ ! -x "$FLUTTER_SDK/bin/flutter" ]; then
  echo "Clonando Flutter SDK (stable) en $FLUTTER_SDK ..."
  rm -rf "$FLUTTER_SDK"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_SDK"
fi

export PATH="$FLUTTER_SDK/bin:$PATH"

flutter config --no-analytics --enable-web
flutter --version
flutter pub get
flutter build web --release --dart-define="API_BASE_URL=$API_BASE_URL"

echo "Build OK → build/web (API_BASE_URL=$API_BASE_URL)"
