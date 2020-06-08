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

# ssh into radio, set frequency, run on frequency

sshpass -p 'kapilrocks' ssh root@$gn_tx_ip 'FREQ=1.3$(gn_rx)e9;cd dragonradio;cd python;echo $FREQ' 
#sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'cd dragonradio;yes | ./build.sh'   
