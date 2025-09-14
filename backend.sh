#!?bin/bash

LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"

mkdir -p $LOGS_FOLDER

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

CHECK_ROOT(){
    if [ $USERID -ne 0]
    then
    echo -e "$R please run this script with root priveleges $N" | tee -a $LOG_FILE
    exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
       echo -e "$2 is ...$R FAILED $N" | tee -a $LOG_FILE
       exit 1
    else
       echo -e "$2 is...$G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo "script started executing at: $(date)" | tee -a LOG_FILE

CHECK_ROOT

dnf module disable nodejs -y | tee -a $LOG_FILE
VALIDATE $? "Disable default nodejs"

dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "Enable nodejs:20 "

dnf install nodejs -y | tee -a $LOG_FILE
VALIDATE $? "Install nodejs"

id expense | tee -a $LOG_FILE

if [ $? -ne 0 ]
then
   echo -e "expense user not exists..$G created $N"
   useradd expense | tee -a $LOG_FILE
   VALIDATE $? "Creating expense user"
else
    echo -e "expense user already exists...$Y Skipping $N"
fi

mkdir -p /app
VALIDATE $? "creating app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip | tee -a $LOG_FILE
VALIDATE $? "Downloading backend app code"

cd /app
rm -rf /app/* #removing the existed code
unzip /tmp/backend.zip | tee -a $LOG_FILE
VALIDATE $? "Extracting backend app code" 

npm install &>>$LOG_FILE
cp /home/ec2-user/expense-shell-1/backend.service /etc/systemd/system/backend.service

#load the data before running backend
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql client"

mysql -h mysql.awspractice.shop -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Schema is loading is success"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon backend"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enabled backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "Restarted backend"



