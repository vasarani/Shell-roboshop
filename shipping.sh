#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

userid=$(id -u)
logs_folder="/var/log/shell-roboshop"
logs_file="$logs_folder/$0.logs"
mysql_host=mysql.rawsd.in
script_dir=$PWD

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

dnf install maven -y &>>$logs_file
VALIDATE $? "Installing maven"

id roboshop &>>$logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logs_file
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi


mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$logs_file
VALIDATE $? "Downloading shipping code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>>$logs_file
VALIDATE $? "Uzip shipping code"

cd /app
mvn clean package &>>$logs_file
VALIDATE $? "Installing and Building Shipping"

mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "Moving and renaming shipping"

cp $script_dir/1shipping.service /etc/systemd/system/1shipping.service
VALIDATE $? "Created systemctl service"

dnf install mysql -y &>>$logs_file
VALIDATE $? "Installing Mysql"

mysql -h $mysql_host -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then

    mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/schema.sql &>>$logs_file
    mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$logs_file
    mysql -h $mysql_host -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$logs_file
    VALIDATE $? "Loaded data into MySQL"
else
    echo -e "data is already loaded ... $Y SKIPPING $N"
fi

systemctl enable shipping &>>$logs_file
systemctl start shipping
VALIDATE $? "Enabled and started shipping"


