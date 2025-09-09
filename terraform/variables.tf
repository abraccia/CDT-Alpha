variable "network_name" { default = "cdtalpha" }
variable "windows_image_name" { default = "" }
variable "ubuntu_image_name" { default = "" }
variable "keypair" { default = "greyteam" }
variable "windows_flavor" { default = "" }
variable "linux_flavor" { default = "" }
variable "external_network" { default = "MAIN-NAT" }

variable "subnet_cidrs" { default = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"] }
variable "blueteam_cidr" { default = "10.1.0.0/16" }
variable "redteam_cidr" { default = "10.2.0.0/16"}
variable "infra_cidr" { default = "10.3.0.0/16" }
variable "ubuntu_hostnames" { default = ["blog", "database", "icmp", "ssh", "smtp", "imap"] }
variable "gateway_names" { default = ["blue_gateway", "redteam_gateway", "infra_gateway"] }