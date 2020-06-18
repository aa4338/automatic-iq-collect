# Name of image: channel-data-radio-20191003
# This script is run at home without being SSHed into container
# It will SSH into a Tx and Rx container

if test "$#" -lt 3; then
    echo ""
    echo "Use: ./iq_collect <modulation> <TX grid node #> <RX grid node #>"
    echo ""
    sleep 1
    echo "Available Modulations:"
    echo "==============="
    echo "bpsk"
    echo "qam(32/64/128/256)"
    echo "apsk(4/8/16/32/64/128/256)"
    echo ""
    gridcli -l
    exit 1
else

# modulation
# modulation=bpsk
modulation=$1

# defining grid nodes
# gn_tx=15
# gn_rx=17
gn_tx=$2
gn_rx=$3

# starting up respective containers message
echo "Please wait while your containers are being set up."

image=ecet680-lab7-20190805-a11994c9
#ecet680-lab7-20190805-a11994c9
#channel-data-radio-20191003

# Start Containers
gridcli -gn grid$gn_tx --start -i $image
gridcli -gn grid$gn_rx --start -i $image

# finding the ip of them
gn_tx_ip=$(gridcli -gn grid$gn_tx -ip)
gn_rx_ip=$(gridcli -gn grid$gn_rx -ip)

# Used if a DragonRadio build is necessary
# sshpass -p 'kapilrocks' ssh root@$gn_tx_ip 'cd dragonradio;yes | ./build.sh -j5' 
# sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'cd dragonradio;yes | ./build.sh -j5'       






# RX first
# 0 - Start TX
# 1 - Iperf TX
# 2 - Start RX
# 3 - Iperf RX

tmux new-session \; \
    select-pane -t 0 \; \
    split-window -v -p 50 \; \
    split-window -h -p 50 \; \
    select-pane -t 0 \; \
    split-window -h -p 50 \; \
    send-keys 'ls' C-m \; \
    select-pane -t 0 \; \
    send-keys "sshpass -p 'kapilrocks' ssh -X root@$gn_rx_ip" C-m \; 
    
tmux select-pane -t 0 \; \
    send-keys 'sudo apt-get update' C-m \; \
    send-keys 'ifconfig eth1 192.168.10.1' C-m \; \
    send-keys 'cd dragonradio' C-m \; \
    # Start RX
    #tmux send-keys -t 0 "sshpass -p 'kapilrocks' ssh -X root@$gn_rx_ip" C-m


    # send-keys 'ifconfig eth1 192.168.10.1' C-m \; \
    # send-keys 'cd dragonradio' C-m \; \
    # send-keys 'timeout 12 ./dragonradio python/ecet680-radio.py -i 1 -f 1.3${gn_rx}e9 -l logs --log-iq -m $modulation --arq' C-m \; \
    # # Start TX
    # select-pane -t 1 \; \
    # send-keys 'sshpass -p 'kapilrocks' ssh -X root@$gn_rx_ip' C-m \; \
    # send-keys 'sudo apt-get update' C-m \; \
    # send-keys 'ifconfig eth1 192.168.10.1' C-m \; \
    # send-keys 'cd dragonradio' C-m \; \
    # send-keys 'timeout 12 ./dragonradio python/ecet680-radio.py -i 2 -f 1.3${gn_rx}e9 -m $modulation --arq' C-m \; \









# #tmux send-keys -t start_rx "gridcli -gn grid$gn_rx --start -i channel-data-radio-20191003" C-m
# tmux send-keys -t start_rx "sshpass -p 'kapilrocks' ssh -X root@$gn_rx_ip" C-m
# sudo apt-get update

# tmux send-keys -t start_rx "ifconfig eth1 192.168.10.1" C-m
# tmux send-keys -t start_rx "cd dragonradio" C-m

# # Used for Kraus Radio
# # tmux send-keys -t start_rx "./dragonradio python/standalone-radio.py -i 1 -f 1.3${gn_rx}e9 -l logs --log-iq -m $modulation" C-m

# # Used for Dandekar Radio
# tmux send-keys -t start_rx "timeout 12 ./dragonradio python/ecet680-radio.py -i 1 -f 1.3${gn_rx}e9 -l logs --log-iq -m $modulation --arq" C-m

# # TX
# tmux new -d -s start_tx
# #tmux send-keys -t start_tx "gridcli -gn grid$gn_tx --start -i channel-data-radio-20191003" C-m
# tmux send-keys -t start_tx "sshpass -p 'kapilrocks' ssh -X root@$gn_tx_ip" C-m
# tmux send-keys -t start_tx "ifconfig eth1 192.168.10.1" C-m
# tmux send-keys -t start_tx "cd dragonradio" C-m

# # Used for Kraus Radio
# # tmux send-keys -t start_tx "./dragonradio python/standalone-radio.py -i 2 -f 1.3${gn_rx}e9 -l logs --log-iq -m $modulation" C-m

# # Used for Dandekar Radio
# tmux send-keys -t start_tx "timeout 12 ./dragonradio python/ecet680-radio.py -i 2 -f 1.3${gn_rx}e9 -m $modulation --arq" C-m

# # Iperf RX
# tmux new -d -s iperf_rx
# tmux send-keys -t iperf_rx "sshpass -p 'kapilrocks' ssh -X root@$gn_rx_ip" C-m
# tmux send-keys -t iperf_rx "sudo iperf -s -u -i 1" C-m
# sleep 2

# # Iperf TX
# tmux new -d -s iperf_tx
# sleep 1
# tmux send-keys -t iperf_tx "sshpass -p 'kapilrocks' ssh -X root@$gn_rx_ip" C-m
# tmux send-keys -t iperf_tx "sudo iperf -c 10.10.10.1 -u -i 1 -b 200k -t 10" C-m
# echo "Sending/Receiving data packets:"
# sleep 3
# echo "25% Complete"
# sleep 3
# echo "50% Complete"
# sleep 3
# echo "75% Complete"
# sleep 3
# echo "Transmission/Reception Complete"

# # Copy over data
# echo "Copying logs over..."
# sleep 2
# scp root@$gn_rx_ip:~/dragonradio/logs/node-001/radio.h5 .
# mv radio.h5 iq_collect_$modulation.h5
# #sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'cd dragonradio/logs/node-001/;rm *'

# # end message
# echo "Your requested $modulation file has been downloaded."

fi