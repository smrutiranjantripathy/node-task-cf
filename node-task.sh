#!bin/bash

# Update Cache
sudo apt-get update

# Install Nginx
sudo apt-get install nginx -y


# Install git 
sudo apt-get install git -y


# Clone the git repository
git clone http://git@github.com/chetandhembre/hello-world-node.git node_js_task 

# Install Node js
curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
sudo apt-get install -y nodejs




# Running Node js to initiate server
nohup node /home/ubuntu/node_js_task/main.js > output.log &



#Checking if any duplicate entry as below exists
grep "upstream myproject" /etc/nginx/nginx.conf

# IF "upstream" entry exists skip the below block:

if [ $? ]
then
# Editing nginx Config file after launching Node Js server
# Adding Module ngx_http_stub_status_module to keep a track of live connections and requests to server
sudo sed -i '26i upstream myproject { \n   server 127.0.0.1:8080;\n    }\n\n server { \n    listen 80;\n   server_name www.domain.com;\n    location / {\n   proxy_pass http://myproject;\n    }\n   location /nginx_status {\n   # Turn on nginx stats \n  stub_status on;\n   # I do not need logs for stats \n  access_log   off;\n  # Security: Only allow access from 192.168.1.100 IP #\n  allow all;\n  # Send rest of the world to /dev/null #\n #deny all;\n  }\n  }' /etc/nginx/nginx.conf
fi


# Unlink Default Configuration
sudo unlink /etc/nginx/sites-enabled/default


#Reload nginx
sudo service nginx reload



# server_port_number keeps the track of the last port on which the server was launched
server_port_number=8080





#Tracking number of active connections at an interval of 5 seconds

while true 
do 



# Extracting number of active connections
track=$(curl http://localhost/nginx_status | awk 'NR==1{print $3}')
echo "Number of Active Connection" $track 


# Cheking the number of requests and if greater than 100 launching new server
if [ $track -gt 100 ]
then
   echo "Create Server"
   ((server_port_number=server_port_number+1))
    echo " Launching New server on port" $server_port_number
    nohup node /home/ubuntu/node_js_task/main.js --port $server_port_number > output.log &



# Adding the new server to nginx Config file
     line=$(awk "/$server_port_number/{ print NR; exit }" /etc/nginx/nginx.conf)
     echo $line "line number"
     sudo sed -i "$((line+1))"i" server 127.0.0.1:$server_port_number;\n" /etc/nginx/nginx.conf
     echo "Server added to nginx"
     sudo service nginx reload


#Checking if the number of requests is less than 100 then killing the server

elif [ $track -lt 100 ]
then
   process=$(ps -afx | grep $server_port_number | awk 'NR==1{print $1}')
   if [ $server_port_number -gt 8080 ]
   then
   echo "Killing server on port number" $process
   sudo kill $process
   
# Removing the server from nginx config
   sudo sed -i "/$server_port_number/d" /etc/nginx/nginx.conf 
   ((server_port_number=server_port_number-1))

   sudo service nginx reload   

   fi

else
   echo "The statistics are normal"
fi

echo "Halting for 30 seconds before checking the number of requests/active connections."
sleep 30

done
