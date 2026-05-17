import smtplib
import sys
from email.mime.text import MIMEText
from email.header import Header

def send_email(subject, body, to_email):
    # --- 설정 ---
    # Gmail 계정과 앱 비밀번호를 여기에 입력하세요.
    # 주의: 일반 비밀번호가 아닌 '앱 비밀번호'를 사용해야 합니다.
    gmail_user = 'gainworld@gmail.com'
    gmail_password = 'your_app_password_here'  # <--- 여기에 앱 비밀번호를 입력하세요. (보안을 위해 로컬에서만 유지하세요)
    # -----------

    msg = MIMEText(body, 'plain', 'utf-8')
    msg['Subject'] = Header(subject, 'utf-8')
    msg['From'] = gmail_user
    msg['To'] = to_email

    try:
        server = smtplib.SMTP_SSL('smtp.gmail.com', 465)
        server.login(gmail_user, gmail_password)
        server.sendmail(gmail_user, [to_email], msg.as_string())
        server.quit()
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 send_mail.py 'Subject' 'Body'")
        sys.exit(1)
    
    subject = sys.argv[1]
    body = sys.argv[2]
    to_email = 'gainworld@gmail.com'
    
    if send_email(subject, body, to_email):
        print("Mail sent successfully")
    else:
        sys.exit(1)
