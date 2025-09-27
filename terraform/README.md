# Competition Terraform
This is the Terraform used by Alpha team to deploy basic competition infrastructure.

## Topology
The network is subdivided into three subnets, 10.1.0.0/16, 10.2.0.0/16, and 10.3.0.0/16. 10.1 is used for blue team hosts, 10.2 is for red team hosts, and 10.3 is for infrastructure. Blue team network topology includes three Windows server 2019 and seven Ubuntu 22 hosts running various services. Red team topology consists only of ten Kali hosts.

## Deployment
To run, first set the `auth_url` and `tenant_name` variables in main.tf to those of your Openstack deployment and then create and download an application credential from the project and provide the credential and secret in files titled `.app_cred` and `.app_cred_secret`. Then, simply run
```
terraform apply
```
in a terminal to deploy infrastructure and run  
```
terraform destroy
```
to teardown infrastructure