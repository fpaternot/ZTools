#!/usr/bin/env sh

OS=`uname`

###===================================================================================
### L I N U X
###
if [ $OS == "Linux" ]; then

SYSINFO=`head -n 1 /etc/issue`
IFS=$'\n'
UPTIME=`uptime`
D_UP=${UPTIME:1}
MYGROUPS=`groups`
DATE=`date`
KERNEL=`uname -a`
CPWD=`pwd`
ME=`whoami`
CPU=`arch`

printf "<=== SYSTEM ===>\n"
echo "  Distro info:	"$SYSINFO""
printf "  Kernel:\t"$KERNEL"\n"
printf "  Uptime:\t"$D_UP"\n"
free -mt | awk '
/Mem/{print "  Memory:\tTotal: " $2 "Mb\tUsed: " $3 "Mb\tFree: " $4 "Mb"}
/Swap/{print "  Swap:\t\tTotal: " $2 "Mb\tUsed: " $3 "Mb\tFree: " $4 "Mb"}'
printf "  Architecture:\t"$CPU"\n"
cat /proc/cpuinfo | grep "model name\|processor" | awk '
/processor/{printf "  Processor:\t" $3 " : " }
/model\ name/{
i=4
while(i<=NF){
	printf $i
	if(i<NF){
		printf " "
	}
	i++
}
printf "\n"
}'
printf "  Date:\t\t"$DATE"\n"
printf "\n<=== USER ===>\n"
printf "  User:\t\t"$ME" (uid:"$UID")\n"
printf "  Groups:\t"$MYGROUPS"\n"
printf "  Home dir:\t"$HOME"\n"
printf "\n<=== NETWORK ===>\n"
printf "  Hostname:\t"$HOSTNAME"\n"
ip -o addr | awk '/inet /{print "  IP (" $2 "):\t" $4}'
/sbin/route -n | awk '/^0.0.0.0/{ printf "  Gateway:\t"$2"\n" }'
cat /etc/resolv.conf | awk '/^nameserver/{ printf "  Name Server:\t" $2 "\n"}'

###===================================================================================
### A I X
###
elif [ $OS == "AIX" ]; then

prtconf

###===================================================================================
### S O L A R I S
###
elif [ $OS == "Solaris" ]; then

echo "hostname:  \c"
/usr/bin/hostname
echo

echo "model:   \c"
/usr/bin/uname -mi
echo

echo "cpu count: \c"
/usr/bin/dmesg|grep cpu|sed 's/.*\(cpu.*\)/\1/'|awk -F: '{print $1}'|sort -u|wc -l
echo

echo "disks online: \c"
echo "^D"|format 2>/dev/null|grep ".\. "|wc -l
echo

echo "disk types:"
echo
echo "^D"|format 2>/dev/null|grep ".\. "
echo

echo "dns name and aliases:"
echo
nslookup `hostname`|grep Name;nslookup `hostname`|sed -n '/Alias/,$p'
echo

echo "Interfaces:"
echo
netstat -in|grep -v Name|grep -v lo0|awk '{print "Name: " $1 " : IP: " $4}'
echo

echo "Access Restrictions:"
echo
if [ -f /etc/hosts.allow ]
then
 cat /etc/hosts.allow
else
 echo "No host based access restrictions in place"
fi
echo
echo "OS Release: \c"
uname -r

###===================================================================================
### H P - U X
###    
elif [ $OS == "HP-UX" ]; then

/opt/ignite/bin/print_manifest

fi
