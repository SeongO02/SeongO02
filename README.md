# RAW Editor (iPhone)

iPhone용 RAW 편집 앱. Sony ARW, iPhone ProRAW(DNG) 등을 불러와 보정하고 JPEG/HEIC로 내보낸다.

- RAW 디코딩: Apple `CIRAWFilter` (Core Image)
- 보정: 노출·색온도·색조·대비·하이라이트·섀도·채도·생동감·선명도·노이즈 감소
- UI: SwiftUI (iOS 16+)

## Mac에서 실행하기

```bash
brew install xcodegen
git clone https://github.com/seongo02/seongo02.git && cd seongo02
git checkout claude/iphone-raw-editor-k60jn9
xcodegen generate        # RAWEditor.xcodeproj 생성
open RAWEditor.xcodeproj
```

1. Xcode에서 `RAWEditor` 타깃 → Signing & Capabilities → Team을 본인 Apple ID로 선택
2. 아이폰을 연결하고 실행 (▶). 시뮬레이터보다 실기기가 RAW 성능을 정확히 보여준다.
3. 아이폰: 설정 → 개인정보 보호 및 보안 → 개발자 모드 켜기 (처음 한 번)

## 사용법
- 처음 화면에서 사진 앱(ProRAW) 또는 파일 앱(ARW)에서 RAW를 연다.
- 슬라이더 라벨을 두 번 탭하면 해당 항목 초기화.
- 이미지를 누르고 있으면 원본(촬영 당시 설정)이 보인다.
- 오른쪽 위 공유 버튼으로 사진 보관함에 JPEG/HEIC 저장.
