# System Monitoring & IP Notification

이 프로젝트는 리눅스 서버의 시스템 정보를 모니터링하고, 공인 IP 주소가 변경될 경우 관리자에게 이메일로 알림을 보내는 도구입니다.

## 주요 기능
- **공인/로컬 IP 모니터링**: 외부 서비스 및 로컬 인터페이스를 통해 IP 변경을 감지합니다.
- **시간 동기화**: `timedatectl` 또는 `ntpdate`를 사용하여 시스템 시간을 자동으로 동기화합니다.
- **이메일 알림**: Python SMTP를 사용하여 Gmail로 변경 사항을 즉시 전송합니다.
- **자동화**: Root Crontab에 자동으로 등록되어 3시간마다 실행됩니다.

## 요구 사항
- **OS**: Linux (Ubuntu 20.04+ 권장)
- **Python**: 3.x 이상
  - 기본 라이브러리(`smtplib`, `email`)를 사용하므로 별도의 `pip install`은 필요하지 않습니다.
- **도구**: `curl`, `hostname`, `cron`

## 설치 및 설정

### 1. Gmail 앱 비밀번호 생성
1. Google 계정의 **2단계 인증**을 활성화합니다.
2. [앱 비밀번호 생성 페이지](https://myaccount.google.com/apppasswords)에서 새로운 비밀번호를 생성합니다.
3. 생성된 16자리 비밀번호를 메모해 둡니다.

### 2. 스크립트 설정
`send_mail.py` 파일을 열어 다음 정보를 수정합니다:
```python
gmail_user = '관리자_이메일@gmail.com'
gmail_password = '생성한_16자리_앱_비밀번호'
```

`system_monitor.sh` 파일을 열어 다음 정보를 수정합니다:
```bash
EMAIL="알림을_받을_이메일@gmail.com"
USER_HOME="/home/사용자계정"
```

### 3. 실행 및 자동화 등록
스크립트에 실행 권한을 부여하고, 루트 권한으로 실행하여 자동화 등록을 완료합니다.
```bash
chmod +x system_monitor.sh
sudo ./system_monitor.sh
```

## 파일 구조
- `system_monitor.sh`: 메인 쉘 스크립트 (IP 체크, 시간 동기화, Cron 등록)
- `send_mail.py`: 이메일 전송을 담당하는 Python 스크립트
- `.last_known_ip`: 마지막으로 확인된 IP 저장 파일 (자동 생성)
- `system_monitor.log`: 작업 로그 파일 (자동 생성)

## 주의 사항
- 보안을 위해 `send_mail.py`의 앱 비밀번호가 GitHub 등 공용 저장소에 노출되지 않도록 주의하십시오. (이 프로젝트는 `.gitignore`를 통해 로그 및 캐시 파일을 제외합니다.)
