resource "openstack_networking_network_v2" "cdtalpha_net" {
  name = "cdtalpha_net"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "cdtalpha_subnet" {
  count = 3
  name = var.subnet_names[count.index]
  network_id = openstack_networking_network_v2.cdtalpha_net.id
  ip_version = 4
  cidr = var.subnet_cidrs[count.index]
  gateway_ip = cidrhost(var.subnet_cidrs[count.index], 1)
  dns_nameservers = ["129.21.3.17", "129.21.4.18"]
}

resource "openstack_networking_router_v2" "cdtalpha_gateway" {
  name = var.gateway_names[count.index]
  count = 3
  external_network_id = data.openstack_networking_network_v2.external_net.id
  admin_state_up = true
}

resource "openstack_networking_router_interface_v2" "team1_gateway_router_e_int" {
  count = 3
  router_id = openstack_networking_router_v2.cdtalpha_gateway[count.index].id
  subnet_id = openstack_networking_subnet_v2.cdtalpha_subnet[count.index].id
}

data "openstack_networking_network_v2" "external_net" {
  name = var.external_network
}