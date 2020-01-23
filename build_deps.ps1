# simple script to build moonsinter dependencies into the /tmp directory of a linux machine from a windows machine

$USER_AND_IP = $args[0]

scp -q build_deps.sh ${USER_AND_IP}:/tmp
ssh -T $USER_AND_IP 'cd /tmp; chmod +x build_deps.sh; ./build_deps.sh'
