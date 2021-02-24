#!/bin/bash

# if [ "$(id -u)" == 1000 ] ; then
# echo "same" ;
# else 
# id -u
# fi

# if [ "$(whoami)" != 'root' ]; then
#         echo "You have no permission to run $0 as non-root user."
#         #exit 1;
# fi

# if [ "$(getent passwd liveware)" == 2 ]; then
#     echo "user doesn't exist"
#     # echo "user does not exist"
# fi

# if [ "$(getent passwd liveware)" && [ $? == 2 ] ]; then
#     echo "user does not exist"
#     # echo "user does not exist"
# fi

## get UID 
uid=$(id -u)
# echo "uid: $uid"
# UID={$UID:-$uid}
echo $uid
uid=2000
_uid=${UID:-$uid}
echo $_uid 

echo GID

# gid=$(id -g)
# echo "gid: $gid"
# GID={$GID:-$gid}
