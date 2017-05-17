debug=$(config debug)

[[ $debug ]] && set -x

hosts=$(config hosts)
commands=$(config commands)
user=$(config user)
hosts_file=$(config hosts_list)
hosts_exclude=$(config exclude)
full_error_output=$(config output_error)
full_output=$(config output)
ssh_quiet=$(config quiet)

[[ -z $user ]] && user=$USER

[[ $ssh_quiet == true ]] && ssh_quiet_option=" -q"

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

fi

hosts_list=`echo $hosts_list | sed 's/[[:space:]]/\n/g' | sort -u`

for host_exclude in $hosts_exclude; do
  hosts_list=`echo $hosts_list | sed "s/"$host_exclude"//g"`
done

pids=()
rm -f /tmp/.bash-pssh.$$.*
log_postfix=$(date +%s)
for host in $hosts_list ; do
  ssh $ssh_quiet_option -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=10 -t $user@$host "{ $commands ; } " 2>/tmp/.bash-pssh.$$.$host.error >/tmp/.bash-pssh.$$.$host &
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
	cat /tmp/.bash-pssh.$$.$host | sed "s/^/$host:\t/" | tee -a $full_output.$log_postfix
	
	[[ -f /tmp/.bash-pssh.$$.$host.error ]] &&
	cat /tmp/.bash-pssh.$$.$host.error | sed "s/^/E:$host:\t/" >&2 | tee -a $full_error_output.$log_postfix
	
	
	i=$(( $i + 1 ))
done
