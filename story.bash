debug=$(config debug)

[[ $debug ]]; set -x

hosts=$(config hosts)
commands=$(config commands)
hosts_storage=$(config hosts_storage) 
user=$(config user)
hosts_file=$(config hosts_list)

if [[ -n $hosts_file ]]; then
  hosts_list=`cat $hosts_file`
else

for host in $hosts; do
  host_pattern=`echo $host | sed 's/\./\\\./g' | sed 's/*/[-.[:alnum:]]*/g' | sed 's/?/./g'`
  search_results=`grep -Ev '^#' /etc/hosts | grep -o "\<${host_pattern}\>" `
  if [[ "$search_results" == "" ]] ; then
    hosts_list+=" $host"
  else
    hosts_list+=" $search_results"
  fi
done

  hosts_list=`echo $hosts_list | sed 's/[[:space:]]/\n/g' | sort -u`

fi

pids=()
rm -f /tmp/.bash-pssh.$$.*
for host in $hosts_list ; do
  ssh -q -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=10 -t $host "{ $commands ; } " 2>/tmp/.bash-pssh.$$.$host.error >/tmp/.bash-pssh.$$.$host &
  pids[${#pids[*]}]=$!
	{
		while [[ -e /proc/$$ ]] ; do sleep 1s; done;
	kill -9 $! 2>/dev/null
		[[ -f /tmp/.bash-pssh.$$.$host ]] && rm /tmp/.bash-pssh.$$.$host
		[[ -f /tmp/.bash-pssh.$$.$host.error ]] && rm /tmp/.bash-pssh.$$.$host.error
	 }&
done
i=0 
for host in $hosts_list ; do
	[[ -e /proc/${pids[$i]} ]] && 

	wait ${pids[$i]}

	[[ -f /tmp/.bash-pssh.$$.$host ]] &&
	cat /tmp/.bash-pssh.$$.$host | sed "s/^/$host:\t/"
	
	[[ -f /tmp/.bash-pssh.$$.$host.error ]] &&
	cat /tmp/.bash-pssh.$$.$host.error | sed "s/^/E:$host:\t/" >&2 
	
	
	i=$(( $i + 1 ))
done
