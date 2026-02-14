#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting Vercel Build Script..."

# Install Flutter if not present
if [ -d flutter ]; then
  echo "✅ Flutter found, pulling latest..."
  cd flutter
  git pull
  cd ..
else
  echo "📥 Cloning Flutter stable..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi

# Add flutter to path
export PATH="$PATH:`pwd`/flutter/bin"

# Run doctor to verify (and download SDKs)
echo "👨‍⚕️ Running Flutter Doctor..."
flutter doctor

# Generate .env file from Vercel Environment Variables
echo "🔑 Generating .env file..."
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

# App dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Code generation (Critical for Riverpod)
echo "🏭 Running build_runner..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "✅ Build script setup complete. Vercel will now proceed with 'flutter build web'."
