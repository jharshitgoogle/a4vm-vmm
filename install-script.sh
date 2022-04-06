#!/bin/bash
# call to get installer command which will give command to run this script
# curl -H "Content-Type: application/json" "http://$attachservice/installagent0/getinstallercommand/" -d '{"VmId": "vm-1111", "VmName": "vm-cr-1111", "Namespace": "default", "ServiceAccount": "attach-service-sa"}'

bootstrapToken=${bootstrapToken:-}
vmID=${vmID:-}

while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
#        echo $1 $2 # Optional to see the parameter:value result
   fi
  shift
  shift
done

# todo:jharshit: in next PR: how to get this fix ip?
attachServiceEp="10.102.217.150"

echo "Calling attach service to configure workload identity"
configureWIURL="http://""$attachServiceEp""/installagent0/configureworkloadidentityforvm/"
configureWIURL="https://httpbin.org/post"
echo "Hitting "$configureWIURL

Vm_uuid=$(sudo cat /sys/class/dmi/id/product_uuid)
Vm_bios=$(sudo cat /sys/class/dmi/id/bios_version) # or use this: sudo dmidecode -s bios-version
Vm_macid=$(sudo cat /sys/class/net/ens4/address) #sudo ifconfig ens4 # cat /sys/class/net/*/address,

configureResponse=$(curl -s -w "%{http_code}\n" -X POST "$configureWIURL" -H "Content-Type: application/json" -H "Authorization: Bearer $bootstrapToken" -d '{"VmId" : "'"$vmID"'", "Vm_uuid" : "'"$Vm_uuid"'", "Vm_bios" : "'"$Vm_bios"'", "Vm_macid" : "'"$Vm_macid"'"}')
HTTP_STATUS=${configureResponse: -3}
configureResponse=${configureResponse::-3}
>configureResponseBody.txt
echo "$configureResponse" >> configureResponseBody.txt
echo "Configure workload identity status: "$HTTP_STATUS

if [ $HTTP_STATUS != 200 ]
then
  echo "Failed to configure Workload identity"
else
  echo "Configure Workload identity successful , Installing osconfig agent"
  sudo sh -c "echo 'deb http://packages.cloud.google.com/apt google-osconfig-agent-stable main' >> /etc/apt/sources.list"
   curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
   sudo apt-get update
   sudo apt-get install -y google-osconfig-agent

  echo "Starting up osconfig agent"
  sh ./osconfig

  echo "Getting agent running status"
  agent_status=$(systemctl status google-osconfig-agent 2>&1 > /dev/null | grep running)
  agentStatus=false
  if test -z $agent_status; then agentStatus=false && echo "Agent not Running"; else agentStatus=true && echo "Agent Running"; fi

  echo "Updating agent status to attach-service with status "$agentStatus
  UpdateInstallStatusURL="http://""$attachServiceEp""/installagent0/updateinstallstatus/"
  curl -X POST "$UpdateInstallStatusURL" -H "Content-Type: application/json" -H "Authorization: Bearer $bootstrapToken" -H "Content-Type: application/json" -d '{"AgentRunning" : '"$agentStatus"'}'
fi
