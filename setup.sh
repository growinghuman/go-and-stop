#!/bin/bash
# ========================================
# 맞고 (Go & Stop) - Xcode 프로젝트 자동 설정
# ========================================
# 사용법: 터미널에서 ./setup.sh 실행
# ========================================

set -e

echo ""
echo "🎴 맞고 (Go & Stop) - Xcode 프로젝트 설정"
echo "=========================================="
echo ""

# 1. Homebrew 확인
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew가 설치되어 있지 않습니다."
    echo "   아래 명령어로 설치하세요:"
    echo '   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    echo ""
    exit 1
fi
echo "✅ Homebrew 확인됨"

# 2. XcodeGen 설치
if ! command -v xcodegen &> /dev/null; then
    echo "📦 XcodeGen 설치 중..."
    brew install xcodegen
else
    echo "✅ XcodeGen 확인됨"
fi

# 3. Xcode CLI 확인
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode Command Line Tools가 필요합니다."
    echo "   App Store에서 Xcode를 설치하세요."
    exit 1
fi
echo "✅ Xcode 확인됨"

# 4. Assets.xcassets 기본 구조 생성
ASSETS_DIR="GoAndStop/Resources/Assets.xcassets"
mkdir -p "$ASSETS_DIR"

# Contents.json
cat > "$ASSETS_DIR/Contents.json" << 'ASSETEOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
ASSETEOF

# AppIcon.appiconset
APPICON_DIR="$ASSETS_DIR/AppIcon.appiconset"
mkdir -p "$APPICON_DIR"
cat > "$APPICON_DIR/Contents.json" << 'ICONEOF'
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
ICONEOF

# AccentColor
ACCENT_DIR="$ASSETS_DIR/AccentColor.colorset"
mkdir -p "$ACCENT_DIR"
cat > "$ACCENT_DIR/Contents.json" << 'COLOREOF'
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.000",
          "green" : "0.843",
          "red" : "1.000"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
COLOREOF

# LaunchBackground color
LAUNCH_DIR="$ASSETS_DIR/LaunchBackground.colorset"
mkdir -p "$LAUNCH_DIR"
cat > "$LAUNCH_DIR/Contents.json" << 'LAUNCHEOF'
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.100",
          "green" : "0.180",
          "red" : "0.040"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
LAUNCHEOF

echo "✅ Assets.xcassets 생성됨"

# 5. XcodeGen으로 프로젝트 생성
echo "🔨 Xcode 프로젝트 생성 중..."
xcodegen generate

echo ""
echo "✅ 프로젝트 생성 완료!"
echo ""
echo "=========================================="
echo "📱 다음 단계:"
echo "=========================================="
echo ""
echo "1. Xcode에서 프로젝트 열기:"
echo "   open GoAndStop.xcodeproj"
echo ""
echo "2. Signing 설정:"
echo "   프로젝트 선택 → Signing & Capabilities"
echo "   → Team에서 본인 Apple ID 선택"
echo ""
echo "3. 시뮬레이터 실행:"
echo "   상단에서 iPhone 선택 → Cmd+R"
echo ""
echo "4. 실제 기기 설치:"
echo "   아이폰 USB 연결 → 상단에서 아이폰 선택 → Cmd+R"
echo "   (처음: 아이폰 설정 → 일반 → VPN 및 기기 관리 → 신뢰)"
echo ""
echo "=========================================="
echo ""

# 6. Xcode 자동 열기
read -p "🎮 Xcode를 지금 열까요? (y/n): " answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    open GoAndStop.xcodeproj
    echo "🎴 즐거운 맞고 되세요!"
fi
