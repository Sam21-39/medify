#!/bin/bash

# Medify - Keystore Generation Script
# This script generates the upload keystore for Play Store releases

set -e

echo "🔐 Medify Keystore Generation"
echo "=============================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Keystore details
KEYSTORE_PATH="$HOME/medify-upload-keystore.jks"
KEY_ALIAS="medify-upload"
STORE_PASS="medify2024secure"
KEY_PASS="medify2024secure"
VALIDITY=10000
KEY_SIZE=2048

# Check if keystore already exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo -e "${YELLOW}⚠️  Keystore already exists at: $KEYSTORE_PATH${NC}"
    echo ""
    read -p "Do you want to overwrite it? (yes/no): " response
    if [ "$response" != "yes" ]; then
        echo -e "${RED}❌ Aborted. Keeping existing keystore.${NC}"
        exit 1
    fi
    echo -e "${YELLOW}🗑️  Removing existing keystore...${NC}"
    rm -f "$KEYSTORE_PATH"
fi

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo -e "${RED}❌ Error: keytool command not found${NC}"
    echo ""
    echo "Please install Java JDK:"
    echo "  macOS: brew install openjdk@17"
    echo "  Or download from: https://www.oracle.com/java/technologies/downloads/"
    echo ""
    exit 1
fi

echo "📝 Keystore Configuration:"
echo "  Location: $KEYSTORE_PATH"
echo "  Alias: $KEY_ALIAS"
echo "  Password: $STORE_PASS"
echo "  Validity: $VALIDITY days (~27 years)"
echo "  Key Size: $KEY_SIZE bits"
echo ""

# Generate keystore
echo "🔨 Generating keystore..."
echo ""

keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -keyalg RSA \
    -keysize $KEY_SIZE \
    -validity $VALIDITY \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASS" \
    -keypass "$KEY_PASS" \
    -dname "CN=Sumit Pal, OU=Medify, O=Medify, L=KOLKATA, ST=WB, C=IN"

# Check if generation was successful
if [ -f "$KEYSTORE_PATH" ]; then
    echo ""
    echo -e "${GREEN}✅ Keystore generated successfully!${NC}"
    echo ""
    echo "📊 Keystore Details:"
    ls -lh "$KEYSTORE_PATH"
    echo ""
    
    # Verify keystore
    echo "🔍 Verifying keystore..."
    keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$STORE_PASS" -alias "$KEY_ALIAS" | head -n 20
    echo ""
    
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ KEYSTORE SETUP COMPLETE!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo "📌 IMPORTANT - Save this information securely:"
    echo ""
    echo "  Keystore File: $KEYSTORE_PATH"
    echo "  Keystore Password: $STORE_PASS"
    echo "  Key Alias: $KEY_ALIAS"
    echo "  Key Password: $KEY_PASS"
    echo ""
    echo "⚠️  CRITICAL:"
    echo "  • Backup this keystore file to a secure location"
    echo "  • Store passwords in a password manager"
    echo "  • NEVER commit keystore to Git"
    echo "  • Without this keystore, you cannot update your app!"
    echo ""
    echo "📦 Next Steps:"
    echo "  1. Build release app bundle:"
    echo "     fvm flutter build appbundle --release"
    echo ""
    echo "  2. Output location:"
    echo "     build/app/outputs/bundle/release/app-release.aab"
    echo ""
    echo "  3. Upload to Play Console"
    echo ""
else
    echo -e "${RED}❌ Failed to generate keystore${NC}"
    exit 1
fi

