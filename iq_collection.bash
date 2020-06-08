# Name of image: channel-data-radio-20191003
# This script is run at home without being SSHed into container
# It will SSH into a Tx and Rx container


# defining grid nodes
gn_tx=grid10
gn_rx=grid12

# starting up respective containers
gridcli -gn $gn_tx --start -i channel-data-radio-20191003
gridcli -gn $gn_rx --start -i channel-data-radio-20191003

# finding the ip of them
gn_tx_ip=$(gridcli -gn $gn_tx -ip)
gn_rx_ip=$(gridcli -gn $gn_rx -ip)

echo $gn_tx_ip
echo $gn_rx_ip

sshpass -p 'kapilrocks' ssh root@$gn_tx_ip 'cd dragonradio;./build.sh' 
sshpass -p 'kapilrocks' ssh root@$gn_rx_ip 'cd dragonradio;./build.sh'        