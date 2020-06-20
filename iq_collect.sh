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
gn_tx=$2
gn_rx=$3

# starting up respective containers message
echo "Please wait while your containers are being set up."

image=ecet680-lab7-20190805-a11994c9

# Start Containers
gridcli -gn grid$gn_tx --start -i $image
gridcli -gn grid$gn_rx --start -i $image

# finding the ip of them
gn_tx_ip=$(gridcli -gn grid$gn_tx -ip)
gn_rx_ip=$(gridcli -gn grid$gn_rx -ip)

# removing any pre-existing log files
#sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'cd dragonradio/logs/node-001/;rm *'

# Tmux Pane Definitions:
# 0 - Start TX
# 1 - Iperf TX
# 2 - Start RX
# 3 - Iperf RX

tmux kill-session -a
tmux new-session \; \
    select-pane -t 0 \; \
    split-window -v -p 50 \; \
    split-window -h -p 50 \; \
    select-pane -t 0 \; \
    split-window -h -p 50 \; \
    send-keys 'ls' C-m \; \
    select-pane -t 0 \; \
    send-keys -t 2 "sshpass -p 'kapilrocks' ssh -X root@$gn_rx_ip" C-m '' \; \
    send-keys -t 2 'ls' C-m \; \
    send-keys -t 2 'sudo apt-get update' C-m \; \
    send-keys -t 2 'ifconfig eth1 192.168.10.1' C-m \; \
    send-keys -t 2 'cd dragonradio' C-m \; \
    send-keys -t 2 "timeout 15 ./dragonradio python/ecet680-radio.py -i 1 -f 1.3${gn_rx}e9 -l logs --log-iq -m $modulation --arq" C-m '' \; \
    send-keys -t 0 "sshpass -p 'kapilrocks' ssh -X root@$gn_tx_ip" C-m '' \; \
    send-keys -t 0 'sudo apt-get update' C-m \; \
    send-keys -t 0 'ifconfig eth1 192.168.10.1' C-m \; \
    send-keys -t 0 'cd dragonradio' C-m \; \
    send-keys -t 0 "timeout 15 ./dragonradio python/ecet680-radio.py -i 2 -f 1.3${gn_rx}e9 -m $modulation --arq" C-m '' \; \
    send-keys -t 3 "sshpass -p 'kapilrocks' ssh -X root@$gn_rx_ip" C-m '' \; \
    send-keys -t 3 'sleep 3 && sudo iperf -s -u -i 1' C-m \; \
    send-keys -t 1 "sshpass -p 'kapilrocks' ssh -X root@$gn_tx_ip" C-m '' \; \
    send-keys -t 1 'sleep 5 && sudo iperf -c 10.10.10.1 -u -i 1 -b 200k -t 10' C-m \; \
    detach \;

# Copy over data
echo "Copying logs over..."
sleep 10
scp root@$gn_rx_ip:~/dragonradio/logs/node-001/radio.h5 .
mv radio.h5 iq_collect_$modulation.h5


end message
echo "Your requested $modulation file has been downloaded."

read -s -p "Plot? (yes/no) " response
if $(response)=yes then;
    tmux send-keys -t 2 'cd tools' C-m \; \
    tmux send-keys -t 2 'source env/bin/activate' C-m \; \
    tmux send-keys -t 2 './drgui.py ../logs/node-001/radio.h5 --rx 1' C-m \; 
else
fi

fi