
require 'socket'
addr = ['<broadcast>', 6668]# broadcast address
#addr = ('255.255.255.255', 33333) # broadcast address explicitly [might not work ?]
#addr = ['127.0.0.255', 33333] # ??
UDPSock = UDPSocket.new
UDPSock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
data = 'foo';
UDPSock.send(data, 0, addr[0], addr[1])
UDPSock.close

