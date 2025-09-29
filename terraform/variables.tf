variable "network_name" { default = "cdtalpha" }
variable "windows_image_name" { default = "WinSrv2022-20348-2022" }
variable "ubuntu_image_name" { default = "ubuntu-jammy-amd64-cloud-20250628-07-42" }
variable "debian_image_name" { default = "debian-bookworm-amd64-cloud-20250628-05-24"}
variable "kali_image_name" { default = "kali-desktop-2025.9.1"}
variable "keypair" { default = "greyteam" }
variable "windows_flavor" { default = "large" }
variable "linux_flavor" { default = "medium" }
variable "external_network" { default = "MAIN-NAT" }

variable "subnet_cidrs" { default = ["10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"] }
variable "blueteam_cidr" { default = "10.1.0.0/16" }
variable "redteam_cidr" { default = "10.2.0.0/16"}
variable "infra_cidr" { default = "10.3.0.0/16" }
variable "ubuntu_hostnames" { default = ["blog", "database", "icmp", "ssh", "smtp", "ftp", "icmp2"] }
variable "windows_hostnames" { default = ["rdp", "dc", "smb"]}
variable "gateway_names" { default = ["blue_gateway", "redteam_gateway", "infra_gateway"] }
variable "subnet_names" { default = ["blue_net", "red_net", "infra_net"] }