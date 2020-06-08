# Name of image: channel-data-radio-20191003
# This script is run at home without being SSHed into container
# It will SSH into a Tx and Rx container


# defining grid nodes
gn_tx=10
gn_rx=12

# starting up respective containers
gridcli -gn grid$gn_tx --start -i channel-data-radio-20191003
gridcli -gn grid$gn_rx --start -i channel-data-radio-20191003

# finding the ip of them
gn_tx_ip=$(gridcli -gn grid$gn_tx -ip)
gn_rx_ip=$(gridcli -gn grid$gn_rx -ip)

echo $gn_tx_ip
echo $gn_rx_ip

# sshpass -p 'kapilrocks' ssh root@$gn_tx_ip 'cd dragonradio;yes | ./build.sh -j5' 
# sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'cd dragonradio;yes | ./build.sh -j5'       

#tmux
tmux new -d -A -s start_rx
tmux send-keys -t start_rx "sshpass -p 'kapilrocks' ssh root@$gn_rx_ip"
tmux attach -t start_rx
# sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'ifconfig eth1 192.168.10.1;\
# cd dragonradio;./dragonradio python/standalone-radio.py -i 2 -f 1.312e9 --log-iq -m bpsk' 










# creates and goes to a window on the right


# start up the rx radio

# sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'ifconfig eth1 192.168.10.1;\
# cd dragonradio;./dragonradio python/standalone-radio.py -i 2 -f 1.312e9 --log-iq -m bpsk' 

# start up the rx radio

# sshpass -p 'kapilrocks' ssh root@$gn_tx_ip 'ifconfig eth1 192.168.10.1;\
# cd dragonradio;./dragonradio python/standalone-radio.py -i 1 -f 1.312e9 --log-iq -m bpsk' 



# tmux new-session -d -A -s remote_rx_iperf
# tmux send-keys -t remote_rx_iperf "sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'iperf -s -u -i 1'" C-m


# sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'iperf -s -u -i 1'   
# sshpass -p 'kapilrocks' ssh root@$gn_tx_ip 'iperf -c 10.10.10.1 -u -i 1 -b 200k -t 10' 