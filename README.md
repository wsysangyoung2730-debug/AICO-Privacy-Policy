# AICO Privacy Policy

AICO iPhone 앱의 개인정보처리방침을 공개하기 위한 저장소입니다.

## 문서

- 공개 페이지: [`docs/index.html`](docs/index.html)
- 검토·수정용 원본: [`docs/privacy-policy.md`](docs/privacy-policy.md)

두 파일은 동일한 정책 내용을 담습니다. 개인정보 처리 항목이나 앱 동작이 변경되면 시행일과 변경 이력을 함께 갱신해야 합니다.

## Vercel 게시

이 저장소는 별도 서버 코드 없이 `docs` 폴더를 정적 사이트로 배포합니다. `vercel.json`에 필요한 설정이 포함되어 있습니다.

1. Vercel에서 **Add New > Project**를 선택합니다.
2. GitHub의 `wsysangyoung2730-debug/AICO-Privacy-Policy` 저장소를 가져옵니다.
3. Framework Preset은 **Other**, Production Branch는 **main**으로 유지합니다.
4. 저장소의 `vercel.json` 설정을 사용해 배포합니다.

Vercel 프로젝트의 Git 연결을 완료하면 `main`에 변경 사항을 push할 때마다 새 Production Deployment가 자동으로 생성됩니다.

Production URL: <https://aico-privacy-policy.vercel.app/>

배포가 완료되면 고정된 Production Domain을 App Store Connect의 **Privacy Policy URL**과 AICO 앱 내부 링크에 동일하게 사용합니다. 저장소를 조직으로 이전하더라도 이 도메인은 변경하지 않는 것을 권장합니다.

## 운영 정보

- 서비스: AICO
- 운영자 및 개인정보 보호책임자: 우상영
- 문의: [sangyoung2730@naver.com](mailto:sangyoung2730@naver.com)

## 관리 원칙

- 이 저장소에는 실제 이용자의 개인정보, 테스트 데이터 또는 인증정보를 올리지 않습니다.
- 앱의 실제 데이터 처리 동작과 다른 내용을 게시하지 않습니다.
- CloudKit 저장 항목, 공유 범위 또는 삭제 방식이 바뀌면 개인정보처리방침도 함께 수정합니다.
