#!/usr/bin/with-contenv bash
echo "code-server.sh User: $USER"
#su $USER
/usr/bin/code-server --disable-update-check --bind-addr 0.0.0.0:8080 /home/$USER 

#s6-setuidgid $USER /usr/bin/code-server --disable-update-check --bind-addr 0.0.0.0:8080 /home/$USER

#s6-setenvuidgid $USER


#  for line in $( cat /etc/environment ) ; do export $line ; done           
#  exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0
