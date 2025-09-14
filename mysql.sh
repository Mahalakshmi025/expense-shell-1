#!/bin/bash

LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMO.log"

mkdir -p $LOGS_FOLDER

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
       echo -e "$R please run this script with root priveleges $N" | tee -a $LOG_FILE
       exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
       echo -e "$2 is....$R FAILED $N" | tee -a $LOG_FILE
    else
       echo -e "$2 is....$G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf install mysql-server -y | tee -a $LOG_FILE
VALIDATE $? "Installing MYSQL server"

dnf enable mysqld | tee -a $LOG_FILE
VALIDATE $? "Enabled MYSQL server"

dnf start mysqld | tee -a $LOG_FILE
VALIDATE $? "Started MYSQL server"

mysql -h mysql.awspractice.shop -u root -pExpenseApp@1 -e 'show databases;' | tee -a $LOG_FILE
if [ $? -ne 0 ]
then
   echo -e "MYSQL password is not setup, setting now ExpenseApp@1" | tee -a $LOG_FILE
   mysql_secure_installation --set-root-pass ExpenseApp@1
   VALIDATE $? "Setting up root password" 
else 
   echo -e "MYSQL password is already set up....$Y skipping $N" | tee -a $LOG_FILE
fi
