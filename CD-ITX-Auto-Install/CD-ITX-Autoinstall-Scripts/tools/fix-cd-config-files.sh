 # fix-cd-config-files.sh
export CDContainerName=`cat /tmp/CDContainerName.txt`

cd /connect/CFG/cdnode

# Fix initparm.cfg
tempFile=$RANDOM.cfg
sed "s/^\( :comm.info=\).*\;\(.*$\)/\1$CDContainerName\;\2/" ./initparm.cfg >./$tempFile
mv ./$tempFile ./initparm.cfg

# Fix netmap.cfg
tempFile=$RANDOM.cfg
sed -e "s/^\( :comm.info=\).*\;\(.*$\)/\1$CDContainerName\;\2/" -e "s/^\( :tcp.api=\).*\;\(.*$\)/\1$CDContainerName\;\2/" ./netmap.cfg >./$tempFile
mv ./$tempFile ./netmap.cfg

# Fix ndmapi.cfg
cd ../cliapi

tempFile=$RANDOM.cfg
sed -e "s/^\( :tcp.hostname=\).*:/\1$CDContainerName:/" ./ndmapi.cfg >./$tempFile
mv ./$tempFile ./ndmapi.cfg

exit 0