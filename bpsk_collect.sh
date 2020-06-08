# Name of image: channel-data-radio-20191003
# This script is run at home without being SSHed into container
# It will SSH into a Tx and Rx container

if test "$#" -ne 1; then
    echo "Illegal number of parameters"
    echo "Use: ./iq_collect <modulation> <grid node TX> <grid node RX>"
    gridcli -l
fi
break
# modulation
# modulation=bpsk
modulation=$1

# defining grid nodes
# gn_tx=15
# gn_rx=17
gn_tx=$2
gn_rx=$3



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

tmux kill-session -a

# RX first
tmux new -d -s start_rx
tmux send-keys -t start_rx "sshpass -p 'kapilrocks' ssh root@$gn_rx_ip" C-m
tmux send-keys -t start_rx "ifconfig eth1 192.168.10.1" C-m
tmux send-keys -t start_rx "cd dragonradio" C-m
tmux send-keys -t start_rx "./dragonradio python/standalone-radio.py -i 1 -f 1.3${gn_rx}e9 -l logs --log-iq -m $modulation" C-m

# TX
tmux new -d -s start_tx
tmux send-keys -t start_tx "sshpass -p 'kapilrocks' ssh root@$gn_tx_ip" C-m
tmux send-keys -t start_tx "ifconfig eth1 192.168.10.1" C-m
tmux send-keys -t start_tx "cd dragonradio" C-m
tmux send-keys -t start_tx "./dragonradio python/standalone-radio.py -i 2 -f 1.3${gn_rx}e9 -l logs --log-iq -m $modulation" C-m

# Iperf RX
tmux new -d -s iperf_rx
tmux send-keys -t iperf_rx "sshpass -p 'kapilrocks' ssh root@$gn_rx_ip" C-m
tmux send-keys -t iperf_rx "iperf -s -u -i 1" C-m
sleep 2

# Iperf TX
tmux new -d -s iperf_tx
tmux send-keys -t iperf_tx "sshpass -p 'kapilrocks' ssh root@$gn_rx_ip" C-m
tmux send-keys -t iperf_tx "iperf -c 10.10.10.1 -u -i 1 -b 200k -t 10" C-m

# Copy over data
sleep 2
scp root@$gn_rx_ip:~/dragonradio/logs/node-001/radio.h5 .
mv radio.h5 bpsk_collect.h5
sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'cd dragonradio/logs/node-001/;rm *'