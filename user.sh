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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling Nodejs Default version"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enablling Nodejs version 20"

dnf install nodejs -y &>>LOG_FILE
VALIDATE $? "Installing Nodejs"

mkdir -p /opt/app

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "Downloading user.zip"

rm -rf /opt/app/*
cd /opt/app
unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "Unzipping user.zip"

npm install &>>$LOG_FILE
VALIDATE $? "Installing Nodejs dependencies"

id roboshop
if [ $? -ne 0 ]
then 
    useradd --system --home /opt/app --shell /sbin/nologin --comment "System User" roboshop
    VALIDATE $? "Creating roboshop user"
else 
    echo "Roboshop user is already created"
fi 

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Copying user.service file to systemd folder"

systemctl daemeon-reload &>>$LOG_FILE

systemctl enable user &>>$LOG_FILE
VALIDATE $? "Enabling user service"

systemctl start user &>>$LOG_FILE
VALIDATE $? "Starting user service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo "Script executed in $TOTAL_TIME seconds" | tee -a $LOG_FILE