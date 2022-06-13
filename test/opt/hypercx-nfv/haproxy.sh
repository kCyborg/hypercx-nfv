#!/bin/bash

# Upgraded by Frank Morales (frank@virtalus.com) and Franco Diaz (franco@virtalus.com)
# Changelog:

source /var/lib/./onegate.sh

wget -q -O /opt/haproxy.orig https://raw.githubusercontent.com/kCyborg/hypercx-nfv/master/haproxy.cfg

mkdir -p /opt/.haproxy/

haproxy_orig=`sha1sum /opt/haproxy.orig | cut -d ' ' -f 1`
haproxy_current=`sha1sum /etc/haproxy/haproxy.cfg | cut -d ' ' -f 1`
motd_path=/opt/.haproxy/motd

if [ "$haproxy_orig" = "$haproxy_current" ]; then

        echo "I have work to do"

        lb_backends_ports=`cat /opt/.variables/variables | grep -w LB_BACKENDS_PORTS | awk '{sub($1 FS,"")}7'`
        lb_user=`cat /opt/.variables/variables | grep -w LB_USER | cut -d ' ' -f 2`
        lb_pass=`cat /opt/.variables/variables | grep -w LB_PASSWORD | cut -d ' ' -f 2`


        start_haproxy () {
                systemctl start haproxy
        }

        stop_haproxy () {
                systemctl stop haproxy
        }

        configure_haproxy () {
                if [ -n "$lb_backends_ports" ]; then
                        echo "LOAD BALANCER ENABLED." >> /etc/motd
                        echo "LOAD BALANCER ENABLED." >> $motd_path
                        status LB ENABLED 2>/dev/null
                        cat > /etc/haproxy/haproxy.cfg.new << EOF
global
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    stats socket /var/lib/haproxy/stats

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000
EOF

                        add_front_backends
                        configure_haproxy_mgmt_auth
                        check_changes
                        rm -f /opt/ha_ports

                else
                        echo "LOAD BALANCER DISABLED." >> /etc/motd
                        echo "LOAD BALANCER DISABLED." >> $motd_path
                        status LB DISABLED 2>/dev/null
                        echo "Load Balancer variables were not found" >> /etc/motd
                        echo "Load Balancer variables were not found" >> $motd_path
                        info LB "Load Balancer variables were not found" 2>/dev/null
                fi
        }

        add_front_backends () {
                count=1
                for vars in $(echo $lb_backends_ports); do
                        front_port="$(echo $vars | cut -d ":" -f 1)"
                        backends="$(echo $vars | cut -d ":" -f 2)"
                        backend="${backends//,/ }"
                        back_port="$(echo $vars | cut -d ":" -f 3)"
                        echo "LB port $front_port" >> /etc/motd
                        echo "LB port $front_port" >> $motd_path
                        echo "$front_port" >> /opt/ha_ports
                        cat >> /etc/haproxy/haproxy.cfg.new <<EOF

frontend main$front_port
    bind 0.0.0.0:$front_port
    stats enable
    mode tcp
    use_backend servers$front_port

backend servers$front_port
        mode tcp
        stats enable
        balance roundrobin
        hash-type consistent
        option forwardfor
        option tcp-check
EOF

                        counter=1
                        for back in $(echo $backend); do
                                echo "  server $back $back:$back_port check port $back_port" >> /etc/haproxy/haproxy.cfg.new
                                echo "LB backend $counter: $back" >> /etc/motd
                                echo "LB backend $counter: $back" >>$motd_path
                                info LB_PORT"$front_port"_BACKEND$counter "$back" 2>/dev/null
                                counter=$((counter+1))
                        done
                        count=$((count+1))
                done
        }

        configure_haproxy_mgmt_auth()
        {
            echo "--------------------------------------------------" >> /etc/motd
            echo "--------------------------------------------------" >> $motd_path
            if [ -n "$lb_user" ] && [ -n "$lb_pass" ]; then
                echo "LOAD BALANCER AUTHENTICATION ENABLED" >> /etc/motd
                echo "LOAD BALANCER AUTHENTICATION ENABLED" >> $motd_path
                cat >> /etc/haproxy/haproxy.cfg.new <<EOF
listen stats
        bind 0.0.0.0:8989
        mode http
        stats enable
        stats uri /stats
        stats realm HAProxy\ Statistics
        stats auth $lb_user:$lb_pass
EOF

                echo "Load Balancer monitoring portal URL: http://server_address:8989/stats" >> /etc/motd
                echo "Load Balancer monitoring portal URL: http://server_address:8989/stats" >> $motd_path
                echo "Load Balancer monitoring portal user: $lb_user" >> /etc/motd
                echo "Load Balancer monitoring portal user: $lb_user" >> $motd_path
                echo "Load Balancer monitoring portal password: $lb_pass" >> /etc/motd
                echo "Load Balancer monitoring portal password: $lb_pass" >> $motd_path
            else
                echo "LOAD BALANCER AUTHENTICATION DISABLED. USER and PASSWORD variables were not found" >> /etc/motd
                echo "LOAD BALANCER AUTHENTICATION DISABLED. USER and PASSWORD variables were not found" >> $motd_path
            fi
            echo "--------------------------------------------------" >> /etc/motd
            echo "--------------------------------------------------" >> $motd_path
        }

        check_changes () {
                ha_new="/etc/haproxy/haproxy.cfg.new"
                ha_old="/etc/haproxy/haproxy.cfg"
                rep_ports="$(sort /opt/ha_ports | uniq -d)"
                if [ -n "$rep_ports" ]; then
                        echo "Error: Duplicated frontend port detected. Port $rep_ports" >> /etc/motd
                        echo "Error: Duplicated frontend port detected. Port $rep_ports" >> $motd_path
                        info LB "Error: Duplicated frontend port detected. Port $rep_ports" 2>/dev/null
                elif cmp -s "$ha_new" "$ha_old"; then
                        echo "No modification needed" >> /etc/motd
                        echo "No modification needed" >> $motd_path
                        info LB "No modification needed." 2>/dev/null
                else
                        echo "A change was detected in the configuration file and it will be modified" >> /etc/motd
                        echo "A change was detected in the configuration file and it will be modified" >> $motd_path
                        info LB "A change was detected in the configuration file and it will be modified" 2>/dev/null
                        stop_haproxy
                        mv /etc/haproxy/haproxy.cfg.new /etc/haproxy/haproxy.cfg
                        start_haproxy
                fi
        }

        echo "=========================LOAD_BALANCER========================" >> /etc/motd
        echo "=========================LOAD_BALANCER========================" >> $motd_path
        configure_haproxy

else
        cat $motd_path >> /etc/motd

fi
