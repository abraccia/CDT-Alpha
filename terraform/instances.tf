data "openstack_images_image_v2" "ubuntu_image" {
    name = var.ubuntu_image_name
    most_recent = true
}

data "openstack_images_image_v2" "windows_image" {
    name = var.windows_image_name
    most_recent = true
}