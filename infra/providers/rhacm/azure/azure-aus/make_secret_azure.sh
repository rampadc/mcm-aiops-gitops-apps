#!/usr/bin/env bash

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}


# Set variables
if [[ -z ${AZ_CLIENT_KEY} ]]; then
  echo "Please provide environment variable AZ_CLIENT_KEY contining the Azure Client Secret"
  exit 1
fi

if [[ -z ${AZ_CLIENT_ID} ]]; then
  echo "Please provide environment variable AZ_CLIENT_ID containg the Azure Client ID"
  exit 1
fi

if [[ -z ${AZ_TEN_ID} ]]; then
  echo "Please provide environment variable AZ_TEN_ID containing the Azure Tenant ID"
  exit 1
fi

if [[ -z ${AZ_SUB_ID} ]]; then
  echo "Please provide environment variable AZ_SUB_ID containing the Azure Subscription ID"
  exit 1
fi

if [[ -z ${SSH_PRIV_FILE} ]]; then
  echo "Please provide environment variable SSH_PRIV_FILE"
  exit 1
fi

if [[ -z ${SSH_PUB_FILE} ]]; then
  echo "Please provide environment variable SSH_PUB_FILE"
  exit 1
fi

if [[ -z ${PULL_SECRET} ]]; then
  echo "Please provide environment variable PULL_SECRET"
  exit 1
fi

SEALED_SECRET_NAMESPACE=${SEALED_SECRET_NAMESPACE:-sealed-secrets}
SEALED_SECRET_CONTROLLER_NAME=${SEALED_SECRET_CONTROLLER_NAME:-sealed-secrets}

#form the data strucutre containing all the different ids

#read in public ssh key
ssh_pub_key=$(cat ${SSH_PUB_FILE})
ssh_priv_key=$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' ${SSH_PRIV_FILE})

#extract values from values.yaml
eval $(parse_yaml values.yaml "VALUES_")

#generate the provider config metadata.
read -r -d  '' provider_config << EOM
baseDomainResourceGroupName: $VALUES_provider__resource_group
clientId: $AZ_CLIENT_ID
clientSecret: $AZ_CLIENT_KEY
subscriptionId: $AZ_SUB_ID
tennantId: $AZ_TEN_ID
baseDomain: $VALUES_provider__baseDomain
pullSecret: '$PULL_SECRET'
sshPrivatekey: "$ssh_priv_key"
sshPublickey: '$ssh_pub_key'
EOM

#remove the install config from templates so helm doesnt try to install it
ENC_PROV_CFG=$(echo -n "$provider_config" | kubeseal --raw --name=$VALUES_connection_name --namespace=openshift-rhacm-providers --controller-namespace $SEALED_SECRET_NAMESPACE --controller-name $SEALED_SECRET_CONTROLLER_NAME --from-file=/dev/stdin)

# Encrypt the secret using kubeseal and private key from the cluster
echo "Creating Secrets"
sed -i '' -e 's#.*providerSecret.*$#providerSecret: '$ENC_PROV_CFG'#g' values.yaml

