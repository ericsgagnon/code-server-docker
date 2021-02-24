#!/bin/sh
set -eu

# We do this first to ensure sudo works below when renaming the user.
# Otherwise the current container UID may not exist in the passwd database.
eval "$(fixuid -q)"

CFG_USER=${USER:-liveware}
CFG_GROUP="${GROUP:-$CFG_USER}"
echo "Pre-usermod:"
id

if [ "$CFG_USER" != "liveware" ] || [ "$CFG_GROUP" != "liveware" ] ; then
    #sudo echo "$CFG_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
    sudo echo 'Defaults        env_keep += "PATH"' | sudo tee -a /etc/sudoers > /dev/null 
    sudo echo "$CFG_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/nopasswd > /dev/null
    #sed "s/liveware/$USER/g" /etc/sudoers.d/nopasswd
    sudo cat /etc/sudoers.d/nopasswd

    sudo usermod --login "$CFG_USER" liveware
    sudo usermod -d /home/"$CFG_USER" -m "$USER"
    sudo cat /etc/passwd

    echo "sudo groupmod -n $CFG_GROUP liveware"
    sudo groupmod -n $CFG_GROUP liveware        
    sudo cat /etc/group

    #sudo sed -i "/liveware/d" /etc/sudoers.d/nopasswd
    sudo mkdir -p /home/$CFG_USER/.local/share/code-server

    #echo "Pre-chown:"
    #id

    ls -alh /home 
    sudo chown -R "$CFG_USER":"$CFG_GROUP" /home/$CFG_USER
    
fi

#dumb-init /usr/bin/code-server "$@"
echo "almost there: $CFG_USER"
sudo -u $CFG_USER dumb-init /usr/bin/code-server --disable-update-check --bind-addr 0.0.0.0:8080 /home/$CFG_USER

# adduser --gecos '' --disabled-password coder && \
#   echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

















# # We do this first to ensure sudo works below when renaming the user.
# # Otherwise the current container UID may not exist in the passwd database.
# eval "$(fixuid -q)"

# if [ "${DOCKER_USER-}" ] && [ "$DOCKER_USER" != "$USER" ]; then
#   echo "$DOCKER_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/nopasswd > /dev/null
#   # Unfortunately we cannot change $HOME as we cannot move any bind mounts
#   # nor can we bind mount $HOME into a new home as that requires a privileged container.
#   sudo usermod --login "$DOCKER_USER" liveware
#   #sudo usermod -d /home/"$DOCKER_USER"
#   sudo groupmod -n "$DOCKER_USER" liveware

#   USER="$DOCKER_USER"

#   sudo sed -i "/liveware/d" /etc/sudoers.d/nopasswd
# fi

# dumb-init /usr/bin/code-server "$@"





# ## get UID 
# uid=$(id -u)
# echo "uid: $uid"
# #uid=${UID:-$uid}
# uid=${UID:-1138}

# gid=$(id -g)
# echo "gid: $gid"
# #gid=${GID:-$gid}
# gid=${GID:-1138}

# #VAR1="${VAR1:-$VAR2}"

# USER=${USER:-testware}
# GROUP=${GROUP:-$USER}

# echo $USER
# echo $GROUP
# useradd $USER -u $uid -s /bin/bash -m 

# # We do this first to ensure sudo works below when renaming the user.
# # Otherwise the current container UID may not exist in the passwd database.
# printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml
# eval "$(fixuid )"

# echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

# dumb-init /usr/bin/code-server "$@"



# usermod -l
