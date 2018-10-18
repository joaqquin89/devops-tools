provider "telefonicaopencloud" {
  user_name   = "${var.openstack_user_name}"
  tenant_name = "${var.openstack_tenant_name}"
  domain_name = "${var.domain_name}"
  password    = "${var.openstack_password}"
  auth_url    = "${var.openstack_auth_url}"
  region      = "${var.otc_region}"
}

variable "vm_count" {
  default = "3"
}

resource "random_id" "name" {
  byte_length = "4"
}

variable "list_names" {
    type = "list"
    default  = ["k8s-cloud1","k8s-cloud2","k8s-cloud3"]
}

resource "telefonicaopencloud_compute_keypair_v2" "k8s-key" {
  name = "k8s-squad-key"
  public_key = ""
}

resource "telefonicaopencloud_compute_instance_v2" "test-server" {
  count     = "${var.vm_count}"
  name      = "${element(var.list_names , count.index )}"
  image_id  = "017087e5-ff00-4902-b37f-678fb2e7401b"
  flavor_id = "c2.xlarge"
  key_pair  = "${telefonicaopencloud_compute_keypair_v2.k8s-key.name}"
  user_data = "${file("cloudinit/cloudinit.tpl")}"
  network {
    uuid = "${var.tenant_network}"
  }
}

//TODO: A veces es necesario atar mas de 1 disco  y el naming seria name-000-count.index
resource "telefonicaopencloud_blockstorage_volume_v2" "test-volume" {
  count       = "${var.vm_count}"
  name        = "${element(concat(telefonicaopencloud_compute_instance_v2.test-server.*.name),count.index )}-disk-001"
  size        = "200"
  volume_type = "SSD"
}

resource "telefonicaopencloud_compute_volume_attach_v2" "test-attach" {
  count       = "${var.vm_count}"
  instance_id = "${element(concat(telefonicaopencloud_compute_instance_v2.test-server.*.id),count.index)}"
  volume_id   = "${element(concat(telefonicaopencloud_blockstorage_volume_v2.test-volume.*.id), count.index)}"
}
