#!/bin/bash 

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
USERID=$(id -u)


LOGS_FOLDER="/var/log/shell-script-logs"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #/var/log/shell-script-logs/18-logs.log
MONGODB_HOST=mongodb.sivadevops.space
START_TIME=$(date +%s)
MYSQL_HOST=mysql.sivadevops.space


mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then 
   echo "Error: Please run this script with root previlages" 
   exit 1 # failure is other than 0
fi 

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then 
      echo -e "$2... $R failed $N " | tee -a $LOG_FILE
      exit 1 # failure is other than 0
    else 
     echo -e "$2...$G success $N" | tee -a $LOG_FILE
    fi 

}

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven"


### System user ###
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then 
 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
 VALIDATE $? "Creating roboshop user"
else 
  echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating /app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading code"

cd /app 
VALIDATE $? "Changing to /app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping the code"

mvn clean package  &>>$LOG_FILE
mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Installing dependencies and renaming shipping file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Copying shipping service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable shipping  &>>$LOG_FILE
VALIDATE $? "Enabling shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting shipping"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql-client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarting Shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"

