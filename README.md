# TVH Client

TVHeadend용 안드로이드 앱입니다.

## 기능
- 📺 채널 목록 및 TV 시청
- 📋 EPG (전자 편성표)
- 🎛️ 트랜스코딩 프로파일 선택
- 🔒 HTTP / HTTPS 지원
- 🔐 아이디/비밀번호 인증 지원 (선택)

## APK 빌드 방법

### 1단계: GitHub 계정 만들기
https://github.com 에서 무료 계정 생성

### 2단계: 새 Repository 만들기
1. GitHub에서 **New repository** 클릭
2. 이름: `tvhclient`
3. **Public** 선택
4. **Create repository** 클릭

### 3단계: 소스코드 업로드
이 폴더의 모든 파일을 GitHub에 업로드 (또는 git push)

### 4단계: APK 자동 빌드 확인
1. GitHub 저장소에서 **Actions** 탭 클릭
2. "Build APK" 워크플로우가 자동으로 실행됨
3. 완료되면 (약 5~10분) **Artifacts** 에서 `tvhclient-release.zip` 다운로드
4. 압축 해제 후 `app-release.apk` 설치

## 앱 사용법
1. 앱 실행 후 TVHeadend 서버 URL 입력 (예: `https://192.168.1.100:9981`)
2. 채널 목록에서 채널 선택하여 시청
3. 상단 프로파일 버튼으로 트랜스코딩 프로파일 변경
4. 재생 화면에서 EPG 버튼으로 편성표 확인
