#!/bin/bash


#VARIABLES

#application initial password
INITIAL_PASSWORD="P@ssw0rd"

#application mode
NODE_ENV="production"

#application JWT
JWT="mystrongjwt"

#application tcp port 
PORT="5000"

#Mongodb connection string
MONGO_URI="mongodb://127.0.0.1:27017/app"

#Mongodb connection string
MONGO_URI="mongodb://127.0.0.1:27017/app"

#application initial username
INITIAL_USERNAME="theadmin"

#application initial email
INITIAL_EMAIL="dupa@telebot.if.ua"

#Current ip address detection
INITIAL_IP=`curl http://ident.me`

export INITIAL_IP
echo 'INITIAL_IP='${INITIAL_IP}''>> /etc/environment
export NODE_ENV
echo 'NODE_ENV='${NODE_ENV}''>> /etc/environment 
export JWT
echo 'JWT='${JWT}''>> /etc/environment
export PORT
echo 'PORT='${PORT}''>> /etc/environment
export MONGO_URI
echo 'MONGO_URI='${MONGO_URI}''>> /etc/environment
export INITIAL_USERNAME
echo 'INITIAL_USERNAME='${INITIAL_USERNAME}''>> /etc/environment
export INITIAL_EMAIL
echo 'INITIAL_EMAIL='${INITIAL_EMAIL}''>> /etc/environment
export INITIAL_PASSWORD
echo 'INITIAL_PASSWORD='${INITIAL_PASSWORD}''>> /etc/environment


##DEPLOING

sudo env > /root/env.tmp

#Updating software repositories
sudo apt update && sudo apt upgrade -y

#Installing git
sudo apt install git

#Installing mongodb server
sudo apt install mongodb -y

#Installing node.js 14
sudo curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
sudo apt -y install nodejs -y

#Installing pm2 package
sudo npm install pm2@latest -g


#Installing apache web server
sudo apt install apache2 -y

#Clonning software repositiries
cd /home/ubuntu
sudo bash -c 'git clone https://github.com/theyurkovskiy/digichlist-api.git'
sudo bash -c 'git clone https://github.com/theyurkovskiy/digichlist-Admin-UI.git'


#Editing admin routes in source code for adding first admin user
sudo sed -i 's/passport\./\/\/passport\./g' /home/ubuntu/digichlist-api/routes/admin.routes.js 


#Starting application
cd digichlist-api
sudo npm install
sudo pm2 start server.js --name digichlist-api

#Waiting for API to start
sleep 10

#Adding admin user to api server
sudo curl --header "Content-Type: application/json" --request POST --data '{"email":"'${INITIAL_EMAIL}'","password":"'${INITIAL_PASSWORD}'","username":"'${INITIAL_USERNAME}'"}' http://127.0.0.1:5000/api/admin/registration

#Stopping application
sudo pm2 stop digichlist-api

#Removing comments from admin routes source code
cd ..
sudo sed -i 's/\/\/passport\./passport\./g' /home/ubuntu/digichlist-api/routes/admin.routes.js

#Starting application
cd digichlist-api
sudo pm2 start server.js --name digichlist-api
cd ..

#Changing WEBUI BASEURL
sudo sed -i 's/https:\/\/digichlist-api.herokuapp.com\/api\//http:\/\/'${INITIAL_IP}':5000\/api\//g' /home/ubuntu/digichlist-Admin-UI/src/environments/environment.prod.tsx
sudo sed -i 's/https:\/\/digichlist-api.herokuapp.com\/api\//http:\/\/'${INITIAL_IP}':5000\/api\//g' /home/ubuntu/digichlist-Admin-UI/src/environments/environment.tsx


#Building WEBUI
cd digichlist-Admin-UI
sudo npm install
sudo npm run build 

#Publishing WEBUI
sudo rm -rf /var/www/html/*
sudo mv ./build/ /var/www/html -T
sudo chown -R www-data:www-data /var/www/html

echo "RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI} -f [OR]" >> /var/www/html/.htaccess
echo "RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI} -d" >> /var/www/html/.htaccess
echo "RewriteRule ^.*$ - [L]" >> /var/www/html/.htaccess
echo "RewriteRule ^ index.html" >> /var/www/html/.htaccess



#Adding startup command for application in case of reboot
sudo bash -c 'echo "@reboot /usr/bin/pm2 start /home/ubuntu/digichlist-api/server.js --name digichlist-api" >> /etc/crontab'
