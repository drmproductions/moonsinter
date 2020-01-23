# simple script to test moonsinter from a windows machine

$USER_AND_IP = $args[0]
$COMMAND = 'cd /tmp; chmod +x moonsinter; PATH=$PATH:. ' + $args[1]

scp -q moonsinter ${USER_AND_IP}:/tmp
ssh -T $USER_AND_IP $COMMAND
