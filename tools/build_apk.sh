#!/usr/bin/env bash
# 用 Android SDK 自带工具直接构建 dark.apk（不依赖 Gradle）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TC="$ROOT/.toolchain"
JAVA_HOME="$TC/jdk-17.0.20.1+1"
export JAVA_HOME
SDK="$TC/sdk"
BT="$SDK/build-tools/34.0.0"
PLATFORM="$SDK/platforms/android-34/android.jar"

OUT="$ROOT/build"
SRC="$ROOT/app/src/main"
KEYSTORE="$ROOT/keystore/dark.jks"
KS_PASS="darkdark"
KS_ALIAS="dark"
FINAL="$ROOT/dist/dark.apk"

rm -rf "$OUT"
mkdir -p "$OUT/compiled" "$OUT/gen" "$OUT/classes" "$OUT/dex"

echo "[1/7] aapt2 compile"
"$BT/aapt2.exe" compile --dir "$SRC/res" -o "$OUT/compiled/res.zip"

echo "[2/7] aapt2 link"
"$BT/aapt2.exe" link \
  -o "$OUT/base.apk" \
  -I "$PLATFORM" \
  --manifest "$SRC/AndroidManifest.xml" \
  --java "$OUT/gen" \
  --min-sdk-version 23 \
  --target-sdk-version 34 \
  --version-code 1 \
  --version-name 1.0 \
  -0 arsc \
  "$OUT/compiled/res.zip"

echo "[3/7] javac"
"$JAVA_HOME/bin/javac" --release 17 -encoding UTF-8 -cp "$PLATFORM" -d "$OUT/classes" \
  $(find "$OUT/gen" -name '*.java') \
  $(find "$SRC/java" -name '*.java')

echo "[4/7] d8 (dex)"
"$BT/d8.bat" --release --lib "$PLATFORM" --min-api 23 --output "$OUT/dex" \
  $(find "$OUT/classes" -name '*.class')

echo "[5/7] package dex into apk"
python_pack() {
  local PYTHON
  PYTHON="$(command -v python || echo "C:/Users/45574/.workbuddy/binaries/python/envs/default/Scripts/python.exe")"
  "$PYTHON" - "$1" "$2" <<'PY'
import shutil, sys, zipfile
base, dex = sys.argv[1], sys.argv[2]
shutil.copy(base, base + ".tmp")
with zipfile.ZipFile(base + ".tmp", "a", zipfile.ZIP_DEFLATED) as z:
    z.write(dex, "classes.dex")
shutil.move(base + ".tmp", base)
print("packed classes.dex")
PY
}
python_pack "$OUT/base.apk" "$OUT/dex/classes.dex"
cp "$OUT/base.apk" "$OUT/unsigned.apk"

echo "[6/7] zipalign"
"$BT/zipalign.exe" -f -p 4 "$OUT/unsigned.apk" "$OUT/aligned.apk"

echo "[7/7] apksigner"
mkdir -p "$(dirname "$FINAL")"
if [ ! -f "$KEYSTORE" ]; then
  mkdir -p "$(dirname "$KEYSTORE")"
  "$JAVA_HOME/bin/keytool" -genkeypair -v \
    -keystore "$KEYSTORE" -alias "$KS_ALIAS" \
    -keyalg RSA -keysize 2048 -validity 10950 \
    -storetype PKCS12 -storepass "$KS_PASS" -keypass "$KS_PASS" \
    -dname "CN=dark, OU=dark, O=dark, L=Beijing, ST=Beijing, C=CN" > /dev/null 2>&1
  echo "  生成签名密钥 $KEYSTORE"
fi
"$BT/apksigner.bat" sign \
  --ks "$KEYSTORE" --ks-key-alias "$KS_ALIAS" \
  --ks-pass "pass:$KS_PASS" --key-pass "pass:$KS_PASS" \
  --v1-signing-enabled true --v2-signing-enabled true \
  --out "$FINAL" "$OUT/aligned.apk"

"$BT/apksigner.bat" verify --print-certs "$FINAL" | head -5
echo "OK -> $FINAL"
