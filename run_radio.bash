# the containers have been created, the radio has been built
# now set the FREQ based on the RX node name and start the radio based on modulation desired

# defining grid nodes
gn_tx=10
gn_rx=12

# finding the ip of them
gn_tx_ip=$(gridcli -gn grid$gn_tx -ip)
gn_rx_ip=$(gridcli -gn grid$gn_rx -ip)

echo $gn_tx_ip
echo $gn_rx_ip

# set the modulations you want
modulation_tx = bpsk
modulation_rx = bpsk

# connect ethernet, set frequency, run radio
sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'ifconfig eth1 192.168.10.1;\
cd dragonradio;\
nohup ./dragonradio python/standalone-radio.py -i 1 -f 1.312e9 --log-iq -m bpsk' 

# do the same with tx 
sshpass -p 'kapilrocks' ssh root@$gn_tx_ip 'ifconfig eth1 192.168.10.1;\
cd dragonradio;\
nohup ./dragonradio python/standalone-radio.py -i 2 -f 1.312e9 --log-iq -m bpsk' 
