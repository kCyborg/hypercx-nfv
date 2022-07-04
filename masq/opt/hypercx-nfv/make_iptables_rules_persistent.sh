#!/bin/bash

# Created by Frank Morales and Franco Diaz (frank@virtalus.com and franco@virtalus.com ) 
# Description: A simple script to make iptables rules persistent.

### Function space
make_iptables_ipv4_persist(){
    filepath=/etc/iptables/rules.v4
    iptables-save > $filepath
    printf "y\n" | iptables-apply $filepath
}

make_iptables_ipv6_persist(){
    filepath=/etc/iptables/rules.v6
    iptables-save > $filepath
    printf "y\n" | iptables-apply $filepath
}

print_help(){
    echo "This script was created with the idea to make permanents the iptables rules."
    echo "The usage is very simple, if you want to make IPv4 iptables rules persistent run the script with the argument as follows:"
    echo " "
    echo "/opt/hypercx-nfv/./make_iptables_rules_persistent.sh 1"
    echo "OR"
    echo "/opt/hypercx-nfv/./make_iptables_rules_persistent.sh ipv4"
    echo " "
    echo " "
    echo "If you want to make IPv6 iptables rules persistent run the script with the argument as follows:"
    echo " "
    echo "/opt/hypercx-nfv/./make_iptables_rules_persistent.sh 2"
    echo "OR"
    echo "/opt/hypercx-nfv/./make_iptables_rules_persistent.sh ipv6"
    echo " "
    echo " "
    echo "If you want to make IPv4 AND IPv6 iptables rules persistent run the script with the argument as follows:"
    echo " "
    echo "/opt/hypercx-nfv/./make_iptables_rules_persistent.sh 3"
    echo "OR"
    echo "/opt/hypercx-nfv/./make_iptables_rules_persistent.sh all"
}

# Body script
case $1 in
  ipv4 | 1)
      make_iptables_ipv4_persist
      ## Exiting from script
      exit 0
      ;;
  ipv6 | 2)
      make_iptables_ipv6_persist
      ## Exiting from script
      exit 0
      ;;
  --help | -h)
      # printhelp
      ## Exiting from script
      exit 0
      ;;
  all | 3) 
      make_iptables_ipv4_persist
      make_iptables_ipv6_persist
      ## Exiting from script
      exit 0
      ;;
  *)
      # printhelp
      ## Exiting from script
      exit 0
      ;;
esac
