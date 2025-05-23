#!/bin/bash
START_TIME=$(date +%s)

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE=$LOG_FOLDER/$SCRIPT_NAME.log

SCRIPT_DIR=$PWD

mkdir -p $LOG_FOLDER
echo "Script started executing at $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then 
    echo -e "$R Error , please run as root user $N" | tee -a $LOG_FILE
    exit 1
else 
    echo -e "$G You are a root user $N" | tee -a $LOG_FILE
fi   

VALIDATE(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$G $2 is successful $N" | tee -a $LOG_FILE
    else 
        echo -e "$R $2 is a failure $N" | tee -a $LOG_FOLDER
        exit 1
    fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing python3 and gcc"

mkdir -p /opt/app

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
VALIDATE $? "Downloading the payment.zip"

rm -rf /opt/app/*

cd /opt/app
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "Unzipping the payment.zip"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Installing the requirements"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "Copying the payment.service file to systemd folder"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading the systemd daemon"


systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Enabling the payment service"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "Starting the payment service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE