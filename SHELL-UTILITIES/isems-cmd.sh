
if [ ! -n "$3" ]; then
 
echo "
Usage: isems-cmd.sh ip key command

Example: isems-cmd.sh 192.168.10.10 secret123 loadoff

Command can be one of:

ftp loadon loadoff mpptstart reboot shell telnet index help .log random
"
exit 0 ; fi

NONCE=`wget -q  $1/random -O -`

echo "
nonce: ${NONCE}
" 

if [ "${NONCE}" == "Encryption not enabled." ]; then
echo "NOTE: Sending password as clear text. 
This is not recommended in public networks.
"

echo "$3+$2" | nc $1  80
echo " 
" 
exit 0 ; fi

NONCESTRING="${NONCE}$2"

echo "noncestring: ${NONCESTRING} 
"

ONETIMEKEY=`echo -n ${NONCESTRING} | sha256sum | cut -d \  -f 1` 

echo "sha256hash: ${ONETIMEKEY}

commandstring: $3+${ONETIMEKEY}
"
echo "$3+${ONETIMEKEY}" | nc $1  80
echo "
" 

