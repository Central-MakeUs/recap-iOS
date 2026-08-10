# 릴리스 절차

## 버전 규칙

| 항목 | 값 | 관리 위치 |
|---|---|---|
| `MARKETING_VERSION` | 사용자에게 보이는 버전 (`1.0.1`) | `project.pbxproj` (6곳) |
| `CURRENT_PROJECT_VERSION` | 빌드 번호 (`8`) | `project.pbxproj` (6곳) |

**Xcode에서 손으로 올리지 않는다.** 저장소 값이 유일한 기준이다.

과거에 손으로 올린 탓에 App Store 배포본은 빌드 7인데 저장소에는 1로 적혀 있었고, 배포본이 어느 커밋에서 나왔는지 알 수 없었다.

빌드 번호가 커밋되어 있으면 배포본의 커밋을 되찾을 수 있다.

```bash
git log --oneline -S "CURRENT_PROJECT_VERSION = 8" --all -- Recap.xcodeproj/project.pbxproj
```

### 올리는 기준

- **패치**(`1.0.1`) — 버그 수정, 설정 교정, 내부 정리. 빠져 있던 연동을 채우는 것도 포함
- **마이너**(`1.1.0`) — 없던 기능이 새로 생길 때
- **빌드 번호** — 제출할 때마다 무조건 증가. 이전 배포본보다 커야 한다

## 절차

### 1. 릴리스 브랜치

```bash
git checkout dev && git pull
git checkout -b release/<버전>
```

### 2. 버전 올리기

`project.pbxproj`의 `MARKETING_VERSION`과 `CURRENT_PROJECT_VERSION`을 수정하고 **커밋한다.**

```bash
git add Recap.xcodeproj/project.pbxproj    # 빠뜨리기 쉽다
git commit -m "버전을 <버전> 빌드 <번호>로 올린다"
git status --short                          # 비어 있어야 한다
```

### 3. 검증

`Config/Secrets.xcconfig`가 있어야 빌드된다. 없으면 실패한다(의도된 동작).

```bash
xcodebuild -project Recap.xcodeproj -scheme Recap \
  -sdk iphoneos -configuration Release \
  -derivedDataPath /tmp/dd-rel build CODE_SIGNING_ALLOWED=NO
```

산출물에서 직접 확인한다.

```bash
APP=/tmp/dd-rel/Build/Products/Release-iphoneos/Recap.app
plutil -extract CFBundleShortVersionString raw -o - "$APP/Info.plist"
plutil -extract CFBundleVersion            raw -o - "$APP/Info.plist"
plutil -extract KAKAO_NATIVE_APP_KEY       raw -o - "$APP/Info.plist"   # 비어 있으면 안 된다
plutil -extract CFBundleVersion            raw -o - "$APP/PlugIns/RecapShareExtension.appex/Info.plist"
```

확인할 것

- [ ] 앱과 공유 확장의 버전·빌드가 **일치**한다 (다르면 제출이 거부된다)
- [ ] `KAKAO_NATIVE_APP_KEY`가 **비어 있지 않다**
- [ ] 빌드 경고 0
- [ ] 테스트 통과
- [ ] **작업 트리가 깨끗한 상태에서** 빌드했다

마지막 항목이 중요하다. 커밋되지 않은 변경으로 빌드하면 산출물과 저장소가 어긋난다.

### 4. 태그

```bash
git push -u origin release/<버전>
git tag -a v<버전> -m "Recap <버전> (빌드 <번호>)

<주요 변경 요약>"
git push origin v<버전>
```

태그는 `v` 접두사를 쓴다. 브랜치명(`release/1.0.1`)이나 버전 문자열과 구분된다.

### 5. 아카이브

**`Config/Secrets.xcconfig`가 있는 머신에서** 아카이브한다. 없으면 빌드가 실패하므로 모르고 넘어갈 일은 없다.

아카이브 후 한 번 더 확인한다.

```bash
plutil -extract KAKAO_NATIVE_APP_KEY raw -o - \
  "<Archive>/Products/Applications/Recap.app/Info.plist"
```

### 6. 제출 전 수동 확인

자동 테스트가 닿지 않는 경로다.

- [ ] **카카오 로그인** — 실기기에서 실제로 로그인해본다
- [ ] **Apple 로그인** — 실기기에서 실제로 로그인해본다

시뮬레이터는 `APP_RUNTIME_PROFILE = mock`으로 떠서 로그인이 스텁으로 처리된다. **실제 인증 경로는 시뮬레이터로 검증되지 않는다.**

## 시크릿

`Config/Secrets.xcconfig`는 `.gitignore` 대상이라 저장소에 없다. 새로 클론했다면 만들어야 한다.

```bash
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# KAKAO_NATIVE_APP_KEY 값을 채운다
```

`Config/App.xcconfig`가 `#include`(물음표 없음)로 이 파일을 요구하므로, 없으면 빌드가 실패한다.

```
Config/App.xcconfig:2:1: error: could not find included file 'Secrets.xcconfig'
```

물음표가 있던 시절에는 파일이 없어도 빌드가 성공했고, 키가 빈 채로 배포되어 카카오 로그인이 크래시했다.
