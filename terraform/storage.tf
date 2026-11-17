resource "libvirt_pool" "vigil" {
  name = "vigil"
  type = "dir"

  target = {
    path = "/var/lib/libvirt/images/vigil"
  }

  create = {
    build     = true
    start     = true
    autostart = true
  }
}

resource "libvirt_volume" "base" {
  name = "${local.image.name}-${local.image.release}.qcow2"
  pool = libvirt_pool.vigil.name

  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = local.image_path
    }
  }

  lifecycle {
    precondition {
      condition     = fileexists(local.image_path) && filesha256(local.image_path) == local.image.sha256
      error_message = "Base image missing or checksum mismatch: run ./fetch-image.sh first."
    }
  }
}
