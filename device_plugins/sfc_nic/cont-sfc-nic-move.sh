#!/bin/bash -x
containerName=${1}
NIC=${2}
oldPID=${3}
BASE_URL=${4}
NS=${5}
POD=${6}
rm -f /var/run/netns/$containerName
#containerID=`docker ps | grep $containerName | awk {'print $1'}`
containerID=`docker -H unix:///gopath/run/docker.sock ps | grep $containerName | awk {'print $1'}`
echo $containerID
while [ -z $containerID ]; do
	echo "sleep"
	containerID=`docker ps | grep $containerName | awk {'print $1'}`
	  sleep 0.1
done
#PID=`docker inspect --format '{{ .State.Pid }}' $containerID`
PID=`docker -H unix:///gopath/run/docker.sock inspect --format '{{ .State.Pid }}' $containerID`
echo "PID is $PID"
#ln -s /proc/$PID/ns/net /var/run/netns/$containerName
#ip link set dev $NIC netns $containerName

IP=$(curl -Gs $BASE_URL/api/v1/namespaces/$NS/pods/$POD | grep -o '"sfc-nic-ip": "[^"]*"'| head -n 1|rev | cut -d: -f1 | rev)
IP=$(eval echo $IP | tr -d '"')
echo IP is $IP

ssh -o StrictHostKeyChecking=no 127.0.0.1 ip netns add dummy
ssh -o StrictHostKeyChecking=no 127.0.0.1 ip netns del $oldPID
ssh -o StrictHostKeyChecking=no 127.0.0.1 ln -s /proc/$PID/ns/net /var/run/netns/$PID
ssh -o StrictHostKeyChecking=no 127.0.0.1 ip link set dev $NIC netns $PID
ssh -o StrictHostKeyChecking=no 127.0.0.1 ip netns exec $PID ip addr add $IP dev $NIC
ssh -o StrictHostKeyChecking=no 127.0.0.1 ip netns exec $PID ip link set $NIC up
