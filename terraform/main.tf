terraform {
  required_providers {
    multipass = {
      source  = "larstobi/multipass"
      version = "~> 1.4.2"
    }
  }
}

provider "multipass" {}


resource "multipass_instance" "worker" {
  name           = "worker-node"
  cpus           = 1
  memory         = "1GiB"
  cloudinit_file = "cloud-init.yaml"
}


resource "multipass_instance" "db" {
  name           = "db-node"
  cpus           = 1
  memory         = "1GiB"
  cloudinit_file = "cloud-init.yaml"
}



output "worker_ip" {
  value = multipass_instance.worker.ipv4
}

output "db_ip" {
  value = multipass_instance.db.ipv4
}