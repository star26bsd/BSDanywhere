#	$OpenBSD: sysctl.conf,v 1.46 2008/01/05 18:38:37 mbalmer Exp $
#
# This file contains a list of sysctl options the user wants set at
# boot time.  See sysctl(3) and sysctl(8) for more information on
# the many available variables.
#
#net.inet.ip.forwarding=1	# 1=Permit forwarding (routing) of IPv4 packets
#net.inet.ip.mforwarding=1	# 1=Permit forwarding (routing) of IPv4 multicast packets
#net.inet.ip.multipath=1	# 1=Enable IP multipath routing
#net.inet6.ip6.forwarding=1	# 1=Permit forwarding (routing) of IPv6 packets
#net.inet6.ip6.mforwarding=1	# 1=Permit forwarding (routing) of IPv6 multicast packets
#net.inet6.ip6.multipath=1	# 1=Enable IPv6 multipath routing
net.inet6.ip6.accept_rtadv=1	# 1=Permit IPv6 autoconf (forwarding must be 0)
#net.inet.tcp.rfc1323=0		# 0=Disable TCP RFC1323 extensions (for if tcp is slow)
#net.inet.tcp.rfc3390=0		# 0=Disable RFC3390 for TCP window increasing
#net.inet.esp.enable=0		# 0=Disable the ESP IPsec protocol
#net.inet.ah.enable=0		# 0=Disable the AH IPsec protocol
#net.inet.esp.udpencap=0	# 0=Disable ESP-in-UDP encapsulation
#net.inet.ipcomp.enable=1	# 1=Enable the IPCOMP protocol
#net.inet.etherip.allow=1	# 1=Enable the Ethernet-over-IP protocol
#net.inet.tcp.ecn=1		# 1=Enable the TCP ECN extension
#net.inet.carp.preempt=1	# 1=Enable carp(4) preemption
#net.inet.carp.log=1		# 1=Enable logging of carp(4) packets
#ddb.panic=0			# 0=Do not drop into ddb on a kernel panic
ddb.console=1			# 1=Permit entry of ddb from the console
#fs.posix.setuid=0		# 0=Traditional BSD chown() semantics
#vm.swapencrypt.enable=0	# 0=Do not encrypt pages that go to swap
#vfs.nfs.iothreads=4		# Number of nfsio kernel threads
#net.inet.ip.mtudisc=0		# 0=Disable tcp mtu discovery
#kern.usercrypto=0		# 0=Disable userland use of /dev/crypto
#kern.splassert=2		# 2=Enable with verbose error messages
#kern.nosuidcoredump=2		# 2=Put suid coredumps in /var/crash
#kern.watchdog.period=32	# >0=Enable hardware watchdog(4) timer if available
#kern.watchdog.auto=0		# 0=Disable automatic watchdog(4) retriggering
machdep.allowaperture=2		# See xf86(4)
machdep.kbdreset=1		# permit console CTRL-ALT-DEL to do a nice halt
