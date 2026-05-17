#!/bin/bash

# =================================================================
# 시스템 모니터링 및 IP 알림 스크립트
# 작성일: 2026-05-17
# 기능: OS 정보 출력, 시간 동기화, IP 변경 시 메일 발송, Cron 자동 등록
# =================================================================

# 0. 변수 설정
EMAIL="gainworld@gmail.com"
SCRIPT_PATH="$(readlink -f "$0")"
# $HOME 변수는 sudo로 실행 시 /root로 바뀔 수 있으므로 명시적 경로 권장
# 하지만 사용자 디렉토리에 캐시를 유지하고 싶다면 고정 경로를 사용
USER_HOME="/home/proidea"
IP_CACHE_FILE="$USER_HOME/.last_known_ip"
LOG_FILE="$USER_HOME/system_monitor.log"

# 루트 권한 체크
if [ "$EUID" -ne 0 ]; then
    echo "오류: 이 스크립트는 루트 권한으로 실행되어야 합니다. (sudo $0)"
    exit 1
fi

echo "--- [$(date)] 작업 시작 ---" >> "$LOG_FILE"

# 1. OS 및 버전 정보 가져오기
get_os_info() {
    echo "[1/4] OS 정보 확인 중..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VER=$VERSION_ID
    else
        OS_NAME=$(uname -s)
        OS_VER=$(uname -r)
    fi
    echo "OS: $OS_NAME, Version: $OS_VER"
}

# 2. 시간 동기화
sync_time() {
    echo "[2/4] 시간 동기화 중..."
    # timedatectl이 있는지 확인 (대부분의 최신 리눅스)
    if command -v timedatectl >/dev/null 2>&1; then
        timedatectl set-ntp true
        echo "timedatectl을 통한 NTP 동기화 활성화 완료."
    elif command -v ntpdate >/dev/null 2>&1; then
        ntpdate pool.ntp.org
        echo "ntpdate를 통한 동기화 완료."
    else
        echo "경고: 시간 동기화 도구(timedatectl, ntpdate)를 찾을 수 없습니다."
    fi
}

# 3. IP 변경 확인 및 메일 발송
check_ip_and_mail() {
    echo "[3/4] IP 변경 확인 중..."
    CURRENT_IP=$(curl -s https://ifconfig.me)
    # 로컬 IP 가져오기 (172., 10., 192. 로 시작하는 것만 필터링)
    LOCAL_IP=$(hostname -I | tr ' ' '\n' | grep -E '^(172\.|10\.|192\.)' | tr '\n' ',' | sed 's/,$//')
    
    if [ -z "$CURRENT_IP" ]; then
        echo "오류: 현재 IP를 가져올 수 없습니다. 네트워크 연결을 확인하세요."
        return
    fi

    if [ -f "$IP_CACHE_FILE" ]; then
        LAST_IP=$(cat "$IP_CACHE_FILE")
    else
        LAST_IP=""
    fi

    if [ "$CURRENT_IP" != "$LAST_IP" ]; then
        echo "IP 변경 감지: $LAST_IP -> $CURRENT_IP"
        echo "gainworld@gmail.com으로 메일을 보냅니다."
        
        # 메일 발송 (mailutils 등이 설치되어 있어야 함)
        MAIL_BODY="시스템 IP가 변경되었습니다.
이전 공인 IP: ${LAST_IP:-"없음"}
현재 공인 IP: $CURRENT_IP
현재 로컬 IP: ${LOCAL_IP:-"없음"}
확인 시간: $(date)"
        
        # 메일 발송 (Python 스크립트 사용)
        # 스크립트 위치를 절대 경로로 지정 (root 실행 시 위치를 못찾을 수 있음)
        python3 /home/proidea/Programming/system_monitoring/send_mail.py "[알림] 서버 IP 변경 ($CURRENT_IP)" "$MAIL_BODY"
        
        if [ $? -eq 0 ]; then
            echo "메일 발송 성공."
        else
            echo "오류: 메일 발송 실패."
        fi
        
        # 새로운 IP 저장
        echo "$CURRENT_IP" > "$IP_CACHE_FILE"
    else
        echo "IP가 변경되지 않았습니다 ($CURRENT_IP). 로컬 IP: $LOCAL_IP"
    fi
}

# 4. Crontab 등록 (3시간에 한 번)
register_cron() {
    echo "[4/4] Crontab 등록 상태 확인 중..."
    CRON_JOB="0 */3 * * * $SCRIPT_PATH >> $LOG_FILE 2>&1"
    
    # 이미 등록되어 있는지 확인
    (crontab -l 2>/dev/null | grep -F "$SCRIPT_PATH" >/dev/null 2>&1)
    if [ $? -ne 0 ]; then
        echo "루트 Crontab에 스크립트를 등록합니다 (3시간 주기)."
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    else
        echo "이미 루트 Crontab에 등록되어 있습니다."
    fi
}

# 메인 실행
get_os_info
sync_time
check_ip_and_mail
register_cron

echo "--- [$(date)] 모든 작업 완료 ---" >> "$LOG_FILE"
