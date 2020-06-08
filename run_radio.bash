# the containers have been created, the radio has been built
# now set the FREQ based on the RX node name and start the radio based on modulation desired

# assumes you are on tmux, fix this later

# defining grid nodes
gn_tx=10
gn_rx=12

# finding the ip of them
gn_tx_ip=$(gridcli -gn grid$gn_tx -ip)
gn_rx_ip=$(gridcli -gn grid$gn_rx -ip)

echo $gn_tx_ip
echo $gn_rx_ip

# # set the modulations you want
# modulation_tx = bpsk
# modulation_rx = bpsk

# # connect ethernet, set frequency, run radio
# run_rx="sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'ifconfig eth1 192.168.10.1;\
# cd dragonradio;./dragonradio python/standalone-radio.py -i 1 -f 1.312e9 --log-iq -m bpsk'"

# # do the same with tx 
# run_tx="sshpass -p 'kapilrocks' ssh root@$gn_tx_ip 'ifconfig eth1 192.168.10.1;ls>text.txt;\
# cd dragonradio;./dragonradio python/standalone-radio.py -i 2 -f 1.312e9 --log-iq -m bpsk'"


# tmux new -s "remote_rx" -d
# tmux send-keys -t "remote_rx" "sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'ifconfig eth1 192.168.10.1;\
# cd dragonradio;./dragonradio python/standalone-radio.py -i 1 -f 1.312e9 --log-iq -m bpsk'" C-m
#tmux kill-ses -t remote

# tmux new -s "remote_tx" -d
# tmux send-keys -t "remote_tx" "sshpass -p 'kapilrocks' ssh root@$gn_tx_ip"
# tmux send-keys -t "remote_tx" "ls>text.txt" C-m
# tmux attach -t "remote_tx" -d
# # tmux send-keys -t "remote_tx" "sshpass -p 'kapilrocks' ssh root@$gn_tx_ip 'ifconfig eth1 192.168.10.1;ls>text.txt;\
# # cd dragonradio;./dragonradio python/standalone-radio.py -i 2 -f 1.312e9 --log-iq -m bpsk'" C-m

# tmux kill-ses -t remote_rx
# tmux kill-ses -t remote_tx

tmux new-session -d -A -s encode
tmux send-keys -t encode "sshpass -p 'kapilrocks' ssh root@$gn_tx_ip 'ifconfig eth1 192.168.10.1;ls>text.txt'" C-m
#tmux kill-ses -t encode

