# SYNOPSIS

Sparrow plugin.

Execute parallel commands via ssh 

For searching by mask using /etc/hosts

# INSTALL

    $ sparrow plg install bash-pssh

# USAGE
## Manually
    
    $ sparrow plg run --param commands=uname  --param hosts="'194.87.235.183 193.124.178.59 my-*-host'"
    
    193.124.178.59:	Linux
    194.87.235.183:	Linux
    my-best-host:	Linux
    my-favoutite-host:	Linux

## via sparrowdo

    
    task-run  %(
      task        => 'show kernel version',
      plugin      => 'bash-pssh',
      parameters  => %( 
       commands    => 'uname -a', 
       hosts => '192.168.23.1 127.0.0.1 my-favourite-host',
      )
    );

# Parameters

## commands

Your commands.

## hosts

list of hosts. 

## hosts_list

list of your hosts in file. Has more priority than command line parameter.

## exclude

exclude one or more hosts.

## user

name of user on remote machines.

Default is your `$HOME` variable.

## output

file for stdout. 

Default file creates in `/tmp/bash-pssh.output`.

## output_error

file for stderr.

Default file creates in `/tmp/bash-pssh.output_error`.

## quiet

Flag for ssh quiet option.

Default is `true`.
