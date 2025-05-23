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

# echo "PLease enter root password"
# read -s MYSQL_ROOT_PASSWORD

VALIDATE(){

    if [ $1 -eq 0 ]
    then 
        echo -e "$2 is $G susccessful$N" | tee -a $LOG_FILE
    else 
        echo -e "$2 is $R failed$N" | tee -a $LOG_FILE
        exit 1
    fi    
}

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven"

mkdir -p /opt/app

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "Downloading the Shiiping.zip"

rm -rf /opt/app/*

cd /opt/app
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping the shipping.zip"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Packaging the shipping application"
mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Renaming the shipping jar file"

id roboshop
if [ $? -ne 0 ]
then 
    useradd --system --home /opt/app --shell /sbin/nologin --comment "System User" roboshop
    VALIDATE $? "Creating roboshop user"
else 
    echo "Roboshop user is already created"
fi 

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying the service file to etc system locatoin"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading the systemd daemon"

systemctl enable shipping 
VALIDATE $? "Enabling the shipping service"

systemctl start shipping
VALIDATE $? "Starting Shipping service"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql client"

mysql -h mysql.persistent.sbs -u root -pRoboShop@1 -e 'use cities' &>>$LOG_FILE

if [ $? -ne 0 ]
then
    mysql -h mysql.persistent.sbs -uroot -pRoboShop@1 < /opt/app/db/schema.sql
    mysql -h mysql.persistent.sbs -uroot -pRoboShop@1 < /opt/app/db/app-user.sql 
    mysql -h mysql.persistent.sbs -uroot -pRoboShop@1 < /opt/app/db/master-data.sql
else 
    echo "Database already exists"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarting the shipping service"



