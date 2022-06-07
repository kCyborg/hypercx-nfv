#!/bin/bash

if [ ! -f /etc/openvpn/server.conf ]; then

    function d2i() {
        echo $(( 0x$( printf "%02x" ${1//./ } ) ))
    }

    function i2d() {
        h=$( printf "%08X" "$1" )
        echo $(( 0x${h:0:2} )).$(( 0x${h:2:2} )).$(( 0x${h:4:2} )).$(( 0x${h:6:2} ))
    }

    function ipmask() {
        i2d $(( $( d2i $1 ) & $( d2i $2 ) ))
    }

    start_openvpn() {
        #systemctl start openvpn@server
        systemctl enable --now openvpn@server
    }

    create_openvpn_client() {
        client_config="/root/vpn_config_files/$1.ovpn"
        cp /etc/openvpn/server.conf $client_config
        echo "client" >> $client_config
        echo "auth-user-pass" >> $client_config
        echo "auth-nocache" >> $client_config
        echo "remote $2 1194 udp" >> $client_config
        echo "<ca>" >> $client_config
        cat /etc/openvpn/pki/ca.crt >> $client_config
        echo "</ca>" >> $client_config
        echo "Created OpenVPN account for user $1" >> /etc/motd
        #info OpenVPN "Created OpenVPN account for user $1" 2>/dev/null
    }

    configure_openvpn() {
        #Generate part of openvpn conf that is common with the client conf
        cat > /etc/openvpn/server.conf <<EOF
dev tun
cipher AES-256-CBC
persist-key
persist-tun
status openvpn-status.log
verb 3
explicit-exit-notify 1
EOF

      echo "$user $pass" >> /etc/openvpn/vpn_users
      create_openvpn_client $user $1

        #Add the rest of the configurations only meant for the server
        cat >> /etc/openvpn/server.conf <<EOF
local $1
ifconfig-pool-persist ipp.txt
keepalive 10 120
topology subnet
port 1194
proto udp
server 192.168.253.0 255.255.255.0
ca pki/ca.crt
cert pki/issued/HyperCX.crt
key pki/private/HyperCX.key
dh dh2048.pem
script-security 3
auth-user-pass-verify /etc/openvpn/check_user_credentials.sh via-env
username-as-common-name
verify-client-cert none
EOF

    # private_ip=`ip -o addr show | grep -v 'inet6' | grep -v 'scope host' | awk '{print $4}' | cut -d '/' -f 1 | grep -E  '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)' | head -1`

        if [ -n "${private_ip}" ]; then

            private_mask=`ip -o addr show | grep -v 'inet6' | grep -v 'scope host' | awk '{print $4}' | grep -E  '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)' | cut -d '/' -f 2 | head -1`

            case $private_mask in
              16)
                private_mask=255.255.0.0
                ;;

              25)
                private_mask=255.255.255.128
                ;;

              26)
                private_mask=255.255.255.192
                ;;

              27)
                private_mask=255.255.255.224
                ;;

              28)
                private_mask=255.255.255.240
                ;;

              24 | *)
                private_mask=255.255.255.0
                ;;

            esac

            private_gateway=`ipmask $private_ip $private_mask`

            echo "push \"route $private_gateway $private_mask\"" >> /etc/openvpn/server.conf
        fi

    }

    get_first_interface_ipv4() {
        cat /opt/.variables/variables | grep -w "ETH0_IP" | cut -d ' ' -f 2
    }

    get_first_interface_floating_ipv4() {
        cat /opt/.variables/variables | grep -w "ETH0_VROUTER_IP" | cut -d ' ' -f 2
    }

    # Variables to work with
    user=`sed '1!d' /opt/openvpn_credentials`
    pass=`sed '2!d' /opt/openvpn_credentials`
    private_ip=`ip -o addr show | grep -v 'inet6' | grep -v 'scope host' | awk '{print $4}' | cut -d '/' -f 1 | grep -E '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)' | head -1`
    public_ip=`ip -o addr show | grep -v 'inet6' | grep -v 'scope host' | awk '{print $4}' | cut -d '/' -f 1 | grep -vE '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)' | head -1`

    # Getting the materials to work with
    wget -q -O /tmp/easyrsa.tgz https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.6/EasyRSA-unix-v3.0.6.tgz
    mkdir -p /etc/openvpn/easy_rsa
    tar -xzf /tmp/easyrsa.tgz -C /etc/openvpn/easy_rsa/ --strip-components=1
    sed -i 's/^.*set_var EASYRSA_CRL_DAYS.*/        set_var EASYRSA_CRL_DAYS        3650/' /etc/openvpn/easy_rsa/easyrsa

    wget -q -O /tmp/pki.tar.gz --header='PRIVATE-TOKEN: nDeb3Fnchryp8YG1-fJo' 'https://gitlab.com/api/v4/projects/20257193/repository/files/openvpn%2Fpki.tar.gz/raw?ref=master'
    wget -q -O /etc/openvpn/dh2048.pem --header='PRIVATE-TOKEN: nDeb3Fnchryp8YG1-fJo' 'https://gitlab.com/api/v4/projects/20257193/repository/files/openvpn%2Fdh2048.pem/raw?ref=master'
    wget -q -O /etc/openvpn/ta.key --header='PRIVATE-TOKEN: nDeb3Fnchryp8YG1-fJo' 'https://gitlab.com/api/v4/projects/20257193/repository/files/openvpn%2Fta.key/raw?ref=master'

    tar -xzf /tmp/pki.tar.gz -C /etc/openvpn/
    chown -R root:root /etc/openvpn/pki
    chown root:root /etc/openvpn/dh2048.pem /etc/openvpn/dh2048.pem /etc/openvpn/check_user_credentials.sh
    chmod 600 /etc/openvpn/ta.key /etc/openvpn/dh2048.pem



    echo "=========================OPENVPN========================" >> /etc/motd
    mkdir -p /root/vpn_config_files
    systemctl stop openvpn@server

    #Clear existing users
    #echo > /etc/openvpn/vpn_users
    ETH0_MAC=`cat /opt/.variables/variables | grep -w ETH0_MAC | cut -d ' ' -f 2`

    if [ -n "${ETH0_MAC}" ]; then

        ETH0_VROUTER_IP=`cat /opt/.variables/variables | grep -w ETH0_VROUTER_IP | cut -d ' ' -f 2`
        if [ -n "${ETH0_VROUTER_IP}" ]; then
            ipv4="$(get_first_interface_floating_ipv4)"
        else
            ipv4="$(get_first_interface_ipv4)"
        fi

        if [ -n "${public_ip}" ]; then

            VPN_CREDENTIALS=`cat /opt/.variables/variables | grep -w "VPN_CREDENTIALS" | cut -d ' ' -f 2`
            if [ -n "${VPN_CREDENTIALS}" ]; then
                echo "OpenVPN ENABLED." >> /etc/motd
                status OpenVPN ENABLED 2>/dev/null
                configure_openvpn $ipv4
                start_openvpn
            else
                echo "OpenVPN DISABLED. ETH0 found using public IP but no users to be configured found." >> /etc/motd
                status OpenVPN DISABLED 2>/dev/null
            fi

        else
            echo "OpenVPN DISABLED. ETH0 found using a private IP ." >> /etc/motd
            status OpenVPN DISABLED 2>/dev/null
        fi

    else
        echo "OpenVPN DISABLED. NO ETH0 MAC." >> /etc/motd
        status OpenVPN DISABLED 2>/dev/null
        #info OpenVPN "NO ETH0 MAC." 2>/dev/null
    fi
fi
