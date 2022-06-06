#!/bin/bash

user=$username
pass=$password

users_file=/etc/openvpn/vpn_users

while read file_user file_password;
do
    echo "user is $user and password is $password"
    if [ "$user" = "$file_user" ]; then
	encoded_pass=$(echo $pass | base64)
        if [ "$encoded_pass" = "$file_password" ]; then
	    exit 0
        else
	    echo "Wrong password found for user $user"
        fi
    fi
done < $users_file

echo "User $user could not be authenticated"
exit 1
