#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

userid=$(id -u)
logs_folder="/var/log/shell-roboshop"
logs_file="$logs_folder/$0.logs"

if [ $userid -ne 0 ]; then
 echo -e "$R Please run this script with the root user access $N" | tee -a $logs_file
 exit 1
fi 

mkdir -p $logs_folder

VALIDATE(){
    if [ $1 -ne 0 ]; then
       echo -e "$2... $R FAILURE $N" | tee -a $logs_file
    else
       echo -e "$2... $G SUCCESS $N" | tee -a $logs_file
    fi      
}

# dnf module disable nodejs -y &>>$logs_file
# VALIDATE $? "Disabling NodeJS Default version"

# dnf module enable nodejs:20 -y &>>$logs_file
# VALIDATE $? "Enabling NodeJS 20"

# dnf install nodejs -y &>>$logs_file
# VALIDATE $? "Install NodeJS"

# id roboshop &>>$logs_file
# if [ $? -ne 0 ]; then
#     useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
#     VALIDATE $? "Creating the system user"
# else
#     echo -e "Roboshop user already exist... $Y SKKIPIMG $N"
# fi 

# mkdir -p /app
# VALIDATE $? "Creating the app directory"

# curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$logs_file
# VALIDATE $? "Downloading catalogue code"

# cd /app
# VALIDATE $? "Moving to app directory"

# rm -r /app/*
# VALIDATE $? "Removing the existing code"

# unzip /tmp/catalogue.zip &>>$logs_file
# VALIDATE $? "unzipcatalogue code"

# npm install
# VALIDATE $? "Installing dependencies"

# cp catalogue.service /etc/systemd/system/catalogue.service
# VALIDATE $? "Created systemctl service"

# systemctl deamon-reload
# systemctl enable catalogue
# systemctl start catalogue
# VALIDATE $? "Starting and Enabling the catalogue"






dnf module disable nodejs -y &>>$logs_file
VALIDATE $? "Disabling NodeJS Default version"

dnf module enable nodejs:20 -y &>>$logs_file
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$logs_file
VALIDATE $? "Install NodeJS"

id roboshop &>>$logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOGS_FILE
VALIDATE $? "Downloading catalogue code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip &>>$logs_file
VALIDATE $? "Uzip catalogue code"

npm install  &>>$logs_file
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable catalogue  &>>$logs_file
systemctl start catalogue
VALIDATE $? "Starting and enabling catalogue"