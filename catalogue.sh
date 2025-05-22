#!/bin/bash

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

echo "Script started executing at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then 
    echo -e "$R Error : $N please run as a root user" | tee -a $LOG_FILE
    exit 1
else 
    echo "You are running as a root user" | tee -a $LOG_FILE
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then 
        echo -e "$2 is ${G} Successfull$N" | tee -a $LOG_FILE
    else 
        echo "$2 is $R failed$N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y &>>LOG_FILE
VALIDATE $? "Disabling Nodejs Default version"

dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "Enablling Nodejs version 20"

dnf install nodejs -y &>>LOG_FILE
VALIDATE $? "Installing Nodejs"

mkdir -p /opt/app
VALIDATE $? "Creating App Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloading catalogue.zip"

rm -rf /opt/app/*

cd /opt/app
unzip /tmp/catalogue.zip &>>LOG_FILE
VALIDATE $? "Unzipping catalogue.zip"

npm install &>>LOG_FILE
VALIDATE $? "Installing Nodejs dependencies"

id roboshop 
if [ $? -ne 0 ]
then 
    useradd --system --home /opt/app --shell /sbin/nologin --comment "System User" roboshop
    VALIDATE $? "Creating roboshop user"
else 
    echo "User Roboshop already exixts"
fi


cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue.service file"

systemctl daemon-reload &>>LOG_FILE

systemctl enable catalogue &>>LOG_FILE
VALIDATE $? "Enabling catalogue service"

systemctl start catalogue &>>LOG_FILE

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongod.repo
VALIDATE $? "Copying MongoDB Repo file"

dnf install mongodb-mongosh -y &>>LOG_FILE
VALIDATE $? "Installing MongoDB client"

STATUS=$(mongosh --host mongodb.persistent.sbs --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $STATUS -lt 0 ]
then 
    mongosh --host mongodb.persistent.sbs </opt/app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Inputing catalogue database"
else 
    echo "Catalogue database already exists"
fi    

