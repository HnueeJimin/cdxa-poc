# CDXA 기반 컴파일러 백도어 탐지 실험

이 저장소는 **CycloneDX 1.6 표준의 Attestation(CDXA) 프레임워크**를 활용하여 빌드 체인 내부에 삽입된 **컴파일러 백도어(compiler backdoor)** 를 탐지할 수 있음을 입증하는 간단한 실험(Proof of Concept, PoC)입니다.

## 🧩 실험 구조

### 1. Clean 빌드
- 정상 컴파일러(`gcc`)로 `hello.c`를 빌드  
- 결과물(`hello-clean`)의 해시 및 BOM(`bom.clean.json`) 생성  
- CDXA `attestations`에 빌드명령·도구정보·해시를 기록

### 2. Borked 빌드 (오염 빌드)
- `compromised-gcc` 래퍼를 통해 소스에 백도어 코드를 주입 후 컴파일  
- 결과물(`hello-borked`)과 BOM(`bom.borked.json`) 생성  
- 동일한 CDXA 구조를 적용하되, `build.command` 값이 달라짐

### 3. 검증
- 서명된 SBOM을 입력받아 다음을 검증:
  1. `cosign` 서명 유효성  
  2. 아티팩트 해시 일치 여부  
  3. 정책(`build.command`가 승인된 컴파일러만 허용) 위반 여부  
- Clean 빌드는 **PASS**, Borked 빌드는 **FAIL**로 판정됨

---

## 🧩 실험 구조 요약

| 구분 | 설명 |
|------|------|
| **정상 빌드** | 표준 `gcc`를 사용해 `hello.c`를 빌드 |
| **오염 빌드** | 래퍼 스크립트 `compromised-gcc`를 통해 악의적 코드를 삽입 |
| **차이점** | 동일한 결과물이 생성되지만, CDXA의 `claims`에서 빌드 명령/경로/서명자 차이가 존재 |
| **검증기(Verifier)** | 서명 및 빌드 명령 정책을 기준으로 무결성 판단 수행 |

---

## 🧠 소스 코드 설명

### 1. `hello.c`
PoC에서는 가장 단순한 C 프로그램을 사용합니다.
```c
#include <stdio.h>

int main() {
    printf("Hello, Secure World!\n");
    return 0;
}
```

## ⚙️ 빌드 및 BOM 생성 절차
정상빌드
```bash
./build_clean.sh # hello-clean, bom.clean.json 생성
```

오염빌드
```bash
./build_borked.sh # hello-borked, bom.borked.json 생성
```

### etc. 환경 설정
```bash
sudo apt install gcc jq
npm install -D @cyclonedx/cdxgen@latest   # Node 22 환경 필요
curl -Lo cosign https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign && sudo mv cosign /usr/local/bin/
cosign generate-key-pair  # cosign.key / cosign.pub 생성
