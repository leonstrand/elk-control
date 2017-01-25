# example of setting required environment variables in bash


# one consul agent per physical elk host
export CONSUL_AGENTS='
host1
host2
'

# unmodified default
export CONSUL_PORT=8500

# elk hosts same as consul agents
export ELK_HOSTS=$CONSUL_AGENTS

# user running elk on elk hosts
export ELK_USER='elk'

# directory of mounted logs from target servers
export LOGSTASH_DIRECTORY_LOGS=/example_directory
# unique name to differentiate logstash containers between purposes
export LOGSTASH_CONTAINER_NAME_PREFIX='logstash-example-prefix'
