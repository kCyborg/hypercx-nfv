#!/bin/bash

check_if_files_equal(){
if cmp --silent -- "$FILE1" "$FILE2"; then
    echo "files contents are identical"
    sudo systemctl stop $service
    sudo systemctl disable $service
else
    echo "files differ"
    sudo systemctl restart $service
    sudo systemctl enable $service
    sudo systemctl start $service

fi
}

service=$1



case $service in
    1 | keepalived)
        service=keepalived
        FILE1=/etc/keepalived/keepalived.conf
        FILE2=/opt/keepalived.conf
        if [ ! -f $FILE1 ]; then
            echo "File not found!"
            systemctl stop keepalived.service
            systemctl disable --now keepalived.service
            exit 0
        else
            wget -q -O /opt/keepalived.conf https://raw.githubusercontent.com/kCyborg/hypercx-nfv/master/keepalived.conf
            check_if_files_equal
        fi
        ;;

    2 | haproxy)
        service=haproxy
        FILE1=/etc/haproxy/haproxy.cfg
        FILE2=/opt/haproxy.cfg

        if [ ! -f $FILE1 ]; then
            echo "File not found!"
            exit 0
        else
            wget -q -O /opt/haproxy.cfg https://raw.githubusercontent.com/kCyborg/hypercx-nfv/master/haproxy.cfg
            check_if_files_equal
        fi
        ;;


    3 | openvpn)
        service=openvpn@server.service
        FILE1=/etc/openvpn/server.conf

        if [ ! -f $FILE1 ]; then
            echo "File not found!"
            sudo systemctl stop $service
            sudo systemctl disable --now $service
            exit 0
        else
            sudo systemctl restart $service
            sudo systemctl enable $service
            sudo systemctl start $service
        fi

        ;;

    4 | nginx)
        service=nginx
        FILE1=/etc/nginx/sites-available/reverse.conf

        if [ ! -f $FILE1 ]; then
            echo "File not found!"
            sudo systemctl stop $service
            sudo systemctl disable --now $service
            exit 0
        else
            sudo systemctl restart $service
            sudo systemctl enable $service
            sudo systemctl start $service
        fi

        ;;
esac

