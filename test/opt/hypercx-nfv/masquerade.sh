#!/bin/bash

# Upgraded by Frank Morales (frank@virtalus.com) and Franco Diaz (franco@virtalus.com)
# Changelog:
# - Added a 2 functions (referencing IPv4 and IPv6) to make the rules persistent

source /var/lib/./onegate.sh

mkdir -p /opt/.masquerade/
motd_path=/opt/.masquerade/motd
flag=/opt/.masquerade/flag

if [ ! -f $flag ]; then

        ### Functions

        # Apply iptables ipv4 rules
        configure_ipv4_masquerade(){
            iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
            echo "IPV4 MASQUERADE ENABLED VIA ETH0" >> /etc/motd
            echo "IPV4 MASQUERADE ENABLED VIA ETH0" >> $motd_path
            info IPv4_MASQUERADE "IPV4 MASQUERADE ENABLED VIA ETH0" 2>/dev/null
        }

        # Apply iptables ipv4 rules
        configure_ipv6_masquerade(){
            ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
            echo "IPV6 MASQUERADE ENABLED VIA ETH0" >> /etc/motd
            echo "IPV6 MASQUERADE ENABLED VIA ETH0" >> $motd_path
            info IPv6_MASQUERADE "IPV6 MASQUERADE ENABLED VIA ETH0" 2>/dev/null
        }

        # Make iptables ipv4 rules persistent
        make_iptables_ipv4_persist(){
            filepath=/etc/iptables/rules.v4
            iptables-save > $filepath
            printf "y\n" | iptables-apply $filepath
        }

        # Make iptables ipv4 rules persistent
        make_iptables_ipv6_persist(){
            filepath=/etc/iptables/rules.v6
            iptables-save > $filepath
            printf "y\n" | iptables-apply $filepath
        }

        # Get eth0 IPv4
        get_first_interface_ipv4() {
            #env | grep -E "^ETH0+_IP=" | cut -d '=' -f 2
            cat /opt/.variables/variables | grep -w ETH0_IP | cut -d ' ' -f 2
        }
        # Get eth0 IPv6
        get_first_interface_ipv6() {
            #env | grep -E "^ETH0+_IP6=" | cut -d '=' -f 2
            cat /opt/.variables/variables | grep -w ETH0_IP6 | cut -d ' ' -f 2
        }

        # Reset iptables rules
        reset_iptables(){
            iptables --flush
            iptables -t nat --flush
        }

        create_masquerade(){
            ETH0_MAC=`cat /opt/.variables/variables | grep -w ETH0_MAC | cut -d ' ' -f 2`    
            if [ -n "${ETH0_MAC}" ]; then
                ipv4="$(get_first_interface_ipv4)"
                    ipv4_private="$(echo $ipv4 | grep -E '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)')"
                ipv6="$(get_first_interface_ipv6)"

                if [ -z "${ipv4_private}" ]; then
                        configure_ipv4_masquerade
                        make_iptables_ipv4_persist
                else
                    echo "IPV4 MASQUERADE DISABLED" >> /etc/motd
                    echo "IPV4 MASQUERADE DISABLED" >> $motd_path
                    status IPv4_MASQUERADE DISABLED 2>/dev/null
                fi
                if [ -n "${ipv6}" ]; then
                        configure_ipv6_masquerade
                        make_iptables_ipv6_persist
                else
                    echo "IPV6 MASQUERADE DISABLED" >> /etc/motd
                    echo "IPV6 MASQUERADE DISABLED" >> $motd_path
                    status IPv6_MASQUERADE DISABLED 2>/dev/null
                fi
            fi
        }


        echo "=========================MASQUERADE========================" >> /etc/motd
        echo "=========================MASQUERADE========================" >> $motd_path
        reset_iptables
        create_masquerade
        touch $flag

else
        cat $motd_path >> /etc/motd
fi

