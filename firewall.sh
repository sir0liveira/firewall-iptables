#!/bin/bash

case $1 in

	start)
		
		iptables -F
		iptables -F -t nat
		iptables -F -t mangle
		iptables -P INPUT DROP
		iptables -P OUTPUT ACCEPT
		iptables -P FORWARD DROP
      		iptables -Z


		#Entrada no Firewall
        	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
		
		#Libera SSH
		iptables -A INPUT -p tcp --syn --dport 19842 -s 10.10.1.0/24 -j ACCEPT
		
		iptables -A INPUT -i eth0 -m state --state NEW -p udp -m multiport --dports 5050,5858  -j ACCEPT
		iptables -A INPUT -p icmp -j ACCEPT	


        	#Compartilhando Internet
        	iptables -t nat  -A POSTROUTING -o eth0 -s 10.10.1.0/24 -j MASQUERADE
		sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
		sysctl -p

        
		#Entrada e Saida da Rede Interna
        	iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
		iptables -A FORWARD -p tcp --syn -m multiport --dports 80,443,465,587,993,995,3050,3306,5222,7777,19842 -s 10.10.1.0/24 -j ACCEPT
		iptables -A FORWARD -p udp --dport 53 -s 10.10.1.0/24 -j ACCEPT
		iptables -A FORWARD -i tap0 -j ACCEPT
		iptables -A FORWARD -p icmp -s 10.10.1.0/24 -j ACCEPT

		
		#Nat para o server VPN
		iptables -t nat -A PREROUTING -p udp -m multiport --dports 5050,5858 -j DNAT --to 10.10.1.254:5050,5858
	
	;;
	stop)
		
		iptables -F
		iptables -F -t nat
		iptables -F -t mangle
		iptables -P INPUT ACCEPT
		iptables -P OUTPUT ACCEPT
		iptables -P FORWARD ACCEPT
        iptables -Z

		
		#Desabilitar Compartilhamento de Internet
		sed -i 's/net.ipv4.ip_forward=1/#net.ipv4.ip_forward=1/g' /etc/sysctl.conf
		sysctl -p
	
	;;
	restart)
		
		$0 stop
		$0 start
    
	;;
	
esac
