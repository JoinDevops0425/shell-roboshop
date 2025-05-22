#!/bin/bash
START_TIME=$(date +%s)

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"


SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executeing at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then 
    echo -e "$R Error : Please run as a root user$N" | tee -a $LOG_FILE
    exit 1
else 
    echo "You are running as a root user" | tee -a $LOG_FILE
fi

VALIDATE(){

    if [ $1 -eq 0 ]
    then 
        echo -e "$2 is $G susccessful$N" | tee -a $LOG_FILE
    else 
        echo -e "$2 is $R failed$N" | tee -a $LOG_FILE
        exit 1
    fi    
}

dnf install mysql-server -y &>>$LOG_FILE   
VALIDATE $? "Installing MySQL Server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabling MySQL Server"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Starting MySQL Server"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
VALIDATE $? "Setting MySQL root password"
