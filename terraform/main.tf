terraform {
required_version = ">= 0.14.0"
   required_providers {
     openstack = {
       source = "terraform-provider-openstack/openstack"
       version = "~> 1.53.0"
     }
   }
 }

provider "openstack" {
  application_credential_id = ""
  application_credential_secret = ""
  auth_url = "https://openstack.cyberrange.rit.edu:5000/v3/"
  tenant_name = "cdtalpha"
}