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
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}


dnf module disable nginx -y &>>LOG_FILE
VALIDATE $? "Disabling Nginx default version"

dnf module enable nginx:1.24 -y &>>LOG_FILE
VALIDATE $? "Enabling Nginx version 1.24"

dnf install nginx -y &>>LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enabling Nginx Service"

systemctl start nginx &>>LOG_FILE
VALIDATE $? "Starting Nginx Service"

rm -rf /usr/share/nginx/html/* 

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip

cd /usr/share/nginx/html
VALIDATE $? "Changing directory to Nginx HTML folder"
unzip /tmp/frontend.zip 
VALIDATE $? "Unzipping frontend.zip"

rm -rf /etc/nginx/nginx.coinf
VALIDATE $? "Removing old nginx.conf file"



cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf

VALIDATE $? "Copying nginx.conf to Nginx folder"

systemctl restart nginx &>>LOG_FILE



