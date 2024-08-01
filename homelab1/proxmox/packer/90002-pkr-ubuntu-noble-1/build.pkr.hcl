source "proxmox-iso" "pkr-ubuntu-noble-1" {
  proxmox_url               = "${var.proxmox_api_url}"
  username                  = "${var.proxmox_api_token_id}"
  token                     = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify  = false

  node                      = "prx-prod-1"
  vm_id                     = "90002"
  vm_name                   = "pkr-ubuntu-noble-1"
  template_description      = "Ubuntu 24.04 LTS"

  iso_file                  = "local:iso/ubuntu-24.04-live-server-amd64.iso"
  iso_storage_pool          = "local"
  unmount_iso               = true
  qemu_agent                = true

  scsi_controller           = "virtio-scsi-pci"

  cores                     = "1"
  sockets                   = "1"
  memory                    = "2048"

  cloud_init                = true
  cloud_init_storage_pool   = "local-lvm"

  vga {
    type                    = "virtio"
  }

  disks {
    disk_size               = "20G"
    format                  = "raw"
    storage_pool            = "local-lvm"
    type                    = "virtio"
  }

  network_adapters {
    model                   = "virtio"
    bridge                  = "vmbr1"
    firewall                = "false"
  }

  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  
  boot                      = "c"
  boot_wait                 = "6s"
  communicator              = "ssh"

  http_directory            = "90002-pkr-ubuntu-noble-1/http"

  ssh_username              = "${var.ssh_username}"
  ssh_password              = "${var.ssh_password}"

  # Raise the timeout, when installation takes longer
  ssh_timeout               = "30m"
  ssh_pty                   = true
  ssh_handshake_attempts    = 15
}

build {

  name    = "pkr-ubuntu-noble-1"
  sources = [
      "proxmox-iso.pkr-ubuntu-noble-1"
  ]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
      inline = [
          "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
          "sudo rm /etc/ssh/ssh_host_*",
          "sudo truncate -s 0 /etc/machine-id",
          "sudo apt -y autoremove --purge",
          "sudo apt -y clean",
          "sudo apt -y autoclean",
          "sudo cloud-init clean",
          "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
          "sudo rm -f /etc/netplan/00-installer-config.yaml",
          "sudo sync"
      ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "90002-pkr-ubuntu-noble-1/files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }
}
