#!/bin/bash
# Mağaza ekran görüntüsü yakalayıcı (6.9" = iPhone 18 Pro Max simülatörü, 1320×2868).
# Gezinme elle/MCP ile yapılır; bu betik o anki ekranı doğru ada kaydeder.
# Kullanım: uretim/magaza/cek.sh <tr|en> <n-ad>     örn. cek.sh tr 1-kadran
set -e
UDID=$(xcrun simctl list devices | grep "SpeedLab iPhone 18 Pro Max" | grep -oE "[0-9A-F-]{36}" | head -1)
[ -n "$UDID" ] || { echo "Simülatör yok: xcrun simctl create 'SpeedLab iPhone 18 Pro Max' com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max com.apple.CoreSimulator.SimRuntime.iOS-27-0"; exit 1; }
OUT="$(dirname "$0")/$1/$2.png"
mkdir -p "$(dirname "$OUT")"
xcrun simctl io "$UDID" screenshot "$OUT" >/dev/null 2>&1
sips -g pixelWidth -g pixelHeight "$OUT" | tail -2 | tr -s ' ' | paste -sd' ' -
echo "$OUT"
