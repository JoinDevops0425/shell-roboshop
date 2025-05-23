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

dnf install golang -y &>>$LOG_FILE
VALIDATE $? "Installing golang"

mkdir -p /opt/app

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip 

cd /opt/app
unzip /tmp/dispatch.zip &>$LOG_FILE
VALIDATE $? "Unzipping the dispatch.zip"

go mod init dispatch &>>$LOG_FILE
VALIDATE $? "Initializing the go module"
go get &>>$LOG_FILE
VALIDATE $? "Getting the go modules"
go build &>>$LOG_FILE
VALIDATE $? "Building the go module"

id roboshop 

if [ $? -ne 0 ] 
then 
    useradd --system --home /opt/app --shell /sbin/nologin roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop user"
else 
    echo "User roboshop already exixts" | tee -a $LOG_FILE
fi

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>>$LOG_FILE
VALIDATE $? "Copying the dispatch.service file to systemd folder"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading the systemd daemon"

systemctl enable dispatch &>>$LOG_FILE
VALIDATE $? "Enabling the dispatch service"

systemctl start dispatch &>>$LOG_FILE
VALIDATE $? "Starting the dispatch service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE