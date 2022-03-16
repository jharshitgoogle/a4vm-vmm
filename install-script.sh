bootstraptoken=$1
vmID=$2
# todo:jharshit: in next PR: how to get this fix ip?
attachServiceEp="10.110.5.236"

echo "Calling attach service to configure workload identity"
configureWIURL="http://""$attachServiceEp""/installagent0/configureworkloadidentityforvm/"
echo "Hitting "$configureWIURL
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$configureWIURL" -H "Content-Type: application/json" -d '{"BootstrapToken" : "'"$bootstrapToken"'", "VmId" : "'"$vmID"'"}')
# todo:jharshit: in next PR: get 4 things and dump into file
echo "configure workload identity status: "$HTTP_STATUS

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
  curl -X POST "$UpdateInstallStatusURL" -H "Content-Type: application/json" -d '{"AgentRunning" : '"$agentStatus"'}'
fi
