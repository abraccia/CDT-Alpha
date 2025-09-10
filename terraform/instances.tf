data "openstack_images_image_v2" "ubuntu_image" {
    name = var.ubuntu_image_name
    most_recent = true
}

data "openstack_images_image_v2" "kali_image" {
    name = var.kali_image_name
    most_recent = true
}

data "openstack_images_image_v2" "windows_image" {
    name = var.windows_image_name
    most_recent = true
}

resource "openstack_compute_instance_v2" "ubuntu_host" {
    count = 7
    name = var.ubuntu_hostnames[count.index]
    flavor_name = var.linux_flavor
    image_name = var.ubuntu_image_name
    

    user_data = file("cloudinit.yml")

    key_pair = var.keypair

    block_device {
        uuid = data.openstack_images_image_v2.ubuntu_image.id
        source_type = "image"
        destination_type = "volume"
        volume_size = 15
        delete_on_termination = true
    }

    network {
        uuid = openstack_networking_network_v2.cdtalpha_net.id
        fixed_ip_v4 = cidrhost(var.blueteam_cidr, count.index+10)
    }
}

resource "openstack_compute_instance_v2" "windows_host" {
    count = 3
    name = var.windows_hostnames[count.index]
    flavor_name = var.windows_flavor
    image_name = var.windows_image_name

    user_data = file("cloudbaseinit.yml")

    key_pair = var.keypair

    block_device {
        uuid = data.openstack_images_image_v2.windows_image.id
        source_type = "image"
        destination_type = "volume"
        volume_size = 15
        delete_on_termination = true
    }

    network {
        uuid = openstack_networking_network_v2.cdtalpha_net.id
        fixed_ip_v4 = cidrhost(var.blueteam_cidr, count.index+17)
    }
}


resource "openstack_compute_instance_v2" "infra" {
    name = "infra"
    flavor_name = var.linux_flavor
    image_name = var.debian_image_name
    user_data = file("infra.yml")
    security_groups = [ "default", "ssh" ]

    key_pair = var.keypair

    block_device {
        uuid = data.openstack_images_image_v2.ubuntu_image.id
        source_type = "image"
        destination_type = "volume"
        volume_size = 15
        delete_on_termination = true
    }

    network {
        uuid = data.openstack_networking_network_v2.external_net.id
        fixed_ip_v4 = "100.65.5.11"
    }

    network {
        uuid = openstack_networking_network_v2.cdtalpha_net.id
        fixed_ip_v4 = cidrhost(var.infra_cidr, 10)
    }

    network {
        uuid = openstack_networking_network_v2.cdtalpha_net.id
        fixed_ip_v4 = cidrhost(var.blueteam_cidr, 100)
    }
}

resource "openstack_compute_instance_v2" "red_box" {
    name = "kali${count.index}"
    count = 10
    flavor_name = var.linux_flavor
    image_name = var.kali_image_name
    user_data = file("cloudinit.yml")

    key_pair = var.keypair

    block_device {
        uuid = data.openstack_images_image_v2.kali_image.id
        source_type = "image"
        destination_type = "volume"
        volume_size = 15
        delete_on_termination = true
    }

    network {
        uuid = openstack_networking_network_v2.cdtalpha_net.id
        fixed_ip_v4 = cidrhost(var.redteam_cidr, count.index + 10)
    }
}