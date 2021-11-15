To Support Secrecy of secrets ansible vault has been integrated into the pipeline as well as jinja templating.

Each provider can have any element templated, with the items in the template encrypted inside an ansible vault.

In the example below the some elements have been templated with {{ }}, the secrets need to be prefixed with secret.

```json
  {
      "name": "eltham-vsphere",
      "description": "My VMware vSphere Connection",
      "connection_parameters": [
          {
              "name": "vsphere_user",
              "value": "{{ secrets.username }}",
              "secured": "false"
          },
          {
              "name": "vsphere_password",
              "value": "{{ secrets.password }}",
              "secured": "true"
          },
          {
              "name": "vsphere_server",
              "value": "{{ secrets.vcenter }}",
              "secured": "false"
          }
      ],
      "configuration_parameters" :[
```

The coresponding secret file looks like the following (before encryption):
```json
{
   "username": "administrator@vsphere.local",
   "password": "password1234",
   "vcenter": "vcenter.demo"
}
```
The secrets file needs to have the same file name as the template, with the extension .enc 

To encrypt:
```
ansible-vault encrypt vsphere.enc
```

To decrypt: (which you need to do to edit the parameters)
```
ansible-vault decrypt vsphere.enc
```
The password used to encrypt needs to be the same as the password thats stored in mcm-gitops secret, under the decrypt_pass key

Currently each cloud-connection needs to reference a providerid, that links the provider (Azure, AWS, GCP etc) definition built into MCM, unforuntently these IDs are unique to each MCM installation. 

To get a list of cloud connections and their IDs,the following can be used;
```
curl -k -X GET \
-H "Authorization: Bearer ${TSA_BEARER_TOKEN}" \
"https://${TSA_HOSTNAME}/cam/api/v1/cloudconnections?tenantId=${TSA_TENANT_ID}&ace_orgGuid=${MCM_TEAM}&cloudOE_spaceGuid=${NAMESPACE}" | json_pp
```

To get a list of the templates and their IDs, the following can be used;
```
curl -k -X GET \
-H "Authorization: Bearer ${TSA_BEARER_TOKEN}" \
"https://${TSA_HOSTNAME}/cam/api/v1/templates?tenantId=${TSA_TENANT_ID}&ace_orgGuid=${MCM_TEAM}&cloudOE_spaceGuid=${NAMESPACE}" |
json_pp
```
For more information refer to;
https://www.ibm.com/docs/en/cloud-paks/cp-management/2.3.x?topic=apis-provider-connection#getcclist
https://www.ibm.com/docs/en/cloud-paks/cp-management/2.3.x?topic=apis-template-template-instance#gettemplist
https://www.ibm.com/docs/en/cloud-paks/cp-management/2.3.x?topic=apis-prerequisites
