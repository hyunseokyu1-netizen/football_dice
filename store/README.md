# Play Store 등록 자료

## 폴더 구조

```
store/
  listing_ko.md            한국어 등록 정보 (앱 이름/짧은 설명/전체 설명/키워드/카테고리/권한)
  listing_en.md             영어 등록 정보
  CHANGELOG.md               버전별 변경 사항 / Play Console 릴리즈 노트 (한/영)
  screenshots/
    ko/  en/                 언어별 휴대전화 스크린샷 (1080×2340, RGB PNG, 4장)
```

## Play Console 업로드 시 참고

- `listing_ko.md` / `listing_en.md` 안의 항목별 텍스트를 해당 로케일(한국어 / English (US))에 그대로 붙여넣으면 된다.
- 새 버전을 낼 때는 `CHANGELOG.md`에 새 버전 섹션을 추가하고, "Play Console 릴리즈 노트" 부분을 What's new에 붙여넣는다.
- 스크린샷은 1080×2340 (실제 화면 그대로), Play Console 요건(최소 320px, 최대 3840px, 2장 이상)을 충족한다. ko/en 각 4장(홈·공격 플레이북·플레이 결과·전체 플레이북).
- 앱 아이콘은 `assets/icon/icon.png` (1024×1024, `flutter_launcher_icons`로 android/ios 모두 적용됨).
- 그래픽 자산이 하나 더 필요할 수 있다: **피처 그래픽(1024×500)**. 아직 만들지 않았다 — 필요하면 요청.

## 릴리즈 서명

- 릴리즈 키스토어: `/Users/hs/Documents/보안문서/keys/football_dice/football_dice-release-key.jks` (git 추적 밖 별도 보안 폴더)
- 설정 파일: `android/key.properties` (비밀번호 포함, **git에 커밋되지 않음** — `android/.gitignore`에 등록됨)
- **이 두 파일은 앱을 업데이트할 때마다 계속 필요하다. 반드시 별도로 백업해둘 것** (분실 시 같은 서명으로 업데이트 불가).

## 빌드된 AAB

`/Users/hs/Documents/workspace/apk_build_files/football_dice/v1.0.0/app-release.aab`

applicationId: `com.backdev.footballdice` · versionName: 1.0.0 · versionCode: 1
