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

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip 
VALIDATE $? "Downloading cart.zip"

rm -rf /opt/app/*
cd /opt/app
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Unzipping cart.zip"

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

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copying cart.service file to systemd folder"

systemctl daemon-reload &>>$LOG_FILE

systemctl enable cart &>>$LOG_FILE
VALIDATE $? "Enabling cart service"

systemctl start cart &>>$LOG_FILE
VALIDATE $? "Starting cart service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo "Script executed in $TOTAL_TIME seconds" | tee -a $LOG_FILE
