#!/bin/bash
set -u
set -e

function usage() {
  echo ""
  echo "Usage:"
  echo "    $0 [--numNodes numberOfNodes]"
  echo ""
  echo "Where:"
  echo "    numberOfNodes is the number of nodes to initialise (default = $numNodes)"
  echo ""
  exit -1
}

numNodes=4
while (( "$#" )); do
    case "$1" in
        --numNodes)
            re='^[0-9]+$'
            if ! [[ $2 =~ $re ]] ; then
                echo "ERROR: numberOfNodes value must be a number"
                usage
            fi
            numNodes=$2
            shift 2
            ;;
        --help)
            shift
            usage
            ;;
        *)
            echo "Error: Unsupported command line parameter $1"
            usage
            ;;
    esac
done

echo "[*] Cleaning up temporary data directories"
rm -rf qdata2
mkdir -p qdata2/logs

echo "[*] Configuring for $numNodes node(s)"
echo $numNodes > qdata2/numberOfNodes

permNodesFile=./permissioned-nodes2.json
#./create-permissioned-nodes2.sh $numNodes

numPermissionedNodes=`grep "enode" ${permNodesFile} |wc -l`
if [[ $numPermissionedNodes -ne $numNodes ]]; then
    echo "ERROR: $numPermissionedNodes nodes are configured in 'permissioned-nodes2.json', but expecting configuration for $numNodes nodes"
    #rm -f $permNodesFile
    exit -1
fi

genesisFile=istanbul-genesis2.json
tempGenesisFile=
#if [[ "${PRIVACY_ENHANCEMENTS:-false}" == "true" ]]; then
#  echo "adding privacyEnhancementsBlock to genesis.config"
#  tempGenesisFile=genesis-pe.json
#  jq '.config.privacyEnhancementsBlock = 0' $genesisFile > $tempGenesisFile
#  genesisFile=$tempGenesisFile
#fi

for i in `seq 1 ${numNodes}`
do
    echo "[*] Configuring node $i"
    mkdir -p qdata2/dd${i}/{keystore,geth}
    cp raft/nodekey${i} qdata2/dd${i}/geth/nodekey
    cp ${permNodesFile} qdata2/dd${i}/static-nodes.json
    if ! [[ -z "${STARTPERMISSION+x}" ]] ; then
        cp ${permNodesFile} qdata/dd${i}/permissioned-nodes.json
    fi
    cp keys/key${i} qdata2/dd${i}/keystore
    geth --datadir qdata2/dd${i} init $genesisFile
done

#Initialise Tessera configuration
#./tessera-init.sh

#Initialise Cakeshop configuration
#./cakeshop-init.sh

rm -f $tempGenesisFile 
