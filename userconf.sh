#!/usr/bin/with-contenv bash

## Set defaults for environmental variables in case they are undefined
USER=${USER:=liveware}
PASSWORD=${PASSWORD:=liveware}
USERID=${USERID:=1138}
GROUPID=${GROUPID:=1138}
#ROOT=${ROOT:=FALSE}
#UMASK=${UMASK:=022}

bold=$(tput bold)
normal=$(tput sgr0)


#echo "export PATH=${PATH}" >> /

CFG_USER=${USER:-liveware}
CFG_GROUP="${GROUP:-$CFG_USER}"
if [ "$CFG_USER" != "liveware" ] || [ "$CFG_GROUP" != "liveware" ] ; then
    echo 'Defaults        env_keep += "PATH"' | sudo tee -a /etc/sudoers > /dev/null 
    echo "$CFG_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd    
    usermod --login "$CFG_USER" liveware
    usermod -d /home/"$CFG_USER" -m "$CFG_USER"
    groupmod -n $CFG_GROUP liveware        
    mkdir -p /home/$CFG_USER/.local/share/code-server
    chown -R "$CFG_USER":"$CFG_GROUP" /home/$CFG_USER  
fi


# populate environment variables
echo "SERVICE_URL=https://open-vsx.org/vscode/gallery" >> /etc/environment
echo "ITEM_URL=https://open-vsx.org/vscode/item" >> /etc/environment
echo "SERVICE_URL=https://marketplace.visualstudio.com/_apis/public/gallery" >> /etc/environment
echo "ITEM_URL=https://marketplace.visualstudio.com/items" >> /etc/environment



# if [[ ${DISABLE_AUTH,,} == "true" ]]
# then
#         mv /etc/rstudio/disable_auth_rserver.conf /etc/rstudio/rserver.conf
#         echo "USER=$USER" >> /etc/environment
# fi



# if grep --quiet "auth-none=1" /etc/rstudio/rserver.conf
# then
#         echo "Skipping authentication as requested"
# elif [ "$PASSWORD" == "rstudio" ]
# then
#     printf "\n\n"
#     tput bold
#     printf "\e[31mERROR\e[39m: You must set a unique PASSWORD (not 'rstudio') first! e.g. run with:\n"
#     printf "docker run -e PASSWORD=\e[92m<YOUR_PASS>\e[39m -p 8787:8787 rocker/rstudio\n"
#     tput sgr0
#     printf "\n\n"
#     exit 1
# fi


# if [ "$USERID" -ne 1000 ]
# ## Configure user with a different USERID if requested.
#   then
#     echo "deleting user rstudio"
#     userdel rstudio
#     echo "creating new $USER with UID $USERID"
#     useradd -m $USER -u $USERID
#     mkdir /home/$USER
#     chown -R $USER /home/$USER
#     usermod -a -G staff $USER
# elif [ "$USER" != "rstudio" ]
#   then
#     ## cannot move home folder when it's a shared volume, have to copy and change permissions instead
#     cp -r /home/rstudio /home/$USER
#     ## RENAME the user
#     usermod -l $USER -d /home/$USER rstudio
#     groupmod -n $USER rstudio
#     usermod -a -G staff $USER
#     chown -R $USER:$USER /home/$USER
#     echo "USER is now $USER"
# fi

# if [ "$GROUPID" -ne 1000 ]
# ## Configure the primary GID (whether rstudio or $USER) with a different GROUPID if requested.
#   then
#     echo "Modifying primary group $(id $USER -g -n)"
#     groupmod -g $GROUPID $(id $USER -g -n)
#     echo "Primary group ID is now custom_group $GROUPID"
# fi

# ## Add a password to user
# echo "$USER:$PASSWORD" | chpasswd

# # Use Env flag to know if user should be added to sudoers
# if [[ ${ROOT,,} == "true" ]]
#   then
#     adduser $USER sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
#     echo "$USER added to sudoers"
# fi

# ## Change Umask value if desired
# if [ "$UMASK" -ne 022 ]
#   then
#     echo "server-set-umask=false" >> /etc/rstudio/rserver.conf
#     echo "Sys.umask(mode=$UMASK)" >> /home/$USER/.Rprofile
# fi

# ## add these to the global environment so they are avialable to the RStudio user
# echo "HTTR_LOCALHOST=$HTTR_LOCALHOST" >> /etc/R/Renviron.site
# echo "HTTR_PORT=$HTTR_PORT" >> /etc/R/Renviron.site
