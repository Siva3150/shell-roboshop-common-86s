#!/bin/bash 

source ./common.sh 

app_name=catalogue 

check_root
app_setup
nodejs_setup
systemd_setup



cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb client"

INDEX=$(mongosh $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')") &>>$LOG_FILE
if [ $INDEX -le 0 ]; then 
   mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
   VALIDATE $? "Loading schema"
else 
 echo  -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi 


app_restart
print_total_time



