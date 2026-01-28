#!/bin/bash



dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs:20"

id roboshop
if [ $? -ne 0 ]
then 
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
   VALIDATE $?  "Creating roboshop system user"
else
   echo -e "System user roboshop already created ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Catalogue"

rm -rf /app/*
cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unziping Catalogue"

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/Catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying the catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE 
systemctl start catalogue 
VALIDATE $? "Starting Catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB client"

STATUS=$(mongosh --host mongodb.prudhvisai.space --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
   mongosh --host mongodb.prudhvisai.space</app/db/master-data.js &>>$LOG_FILE
   VALIDATE $? "Loading the data into the MongoDB"
else
   echo -e "Data is already loaded ... $Y SKIPPING $N"
fi      