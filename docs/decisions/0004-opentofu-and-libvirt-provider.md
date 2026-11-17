# 0004: OpenTofu and the libvirt provider

- **Status:** Accepted
- **Date:** 2026-11-17

## Context

The VMs are created as code on local KVM through libvirt. Terraform and OpenTofu share the same language; OpenTofu
is the open-source fork maintained by the Linux Foundation after Terraform's licence change.

The community `dmacvicar/libvirt` provider was rewritten in 0.9: its schema now mirrors libvirt's XML, and most
examples online target the older 0.7/0.8 schema.

## Decision

- **OpenTofu** (`~> 1.13`).
- **`dmacvicar/libvirt` pinned to exactly `0.9.9`**, with `.terraform.lock.hcl` committed so every machine uses the
  same build (version and checksums).
- The configuration was written against the pinned version's schema (`tofu providers schema -json`) and its own
  examples, not against older online examples.

## Consequences

- An upgrade is deliberate: change the pin, run `tofu init -upgrade`, read the changelog, review the plan.
- 0.9.9 requires a fixed path for a `pty` serial source (normally assigned by libvirt), so the serial port is
  declared without a source. Checked at the first apply (2026-11-17): libvirt makes it a `pty` and `virsh console`
  works.
- 0.9 maps the libvirt XML one to one and adds nothing by default, unlike 0.7/0.8 and `virt-install`. The first
  apply booted without ACPI: on q35 the guest could not power on its PCIe devices (disk, NIC) and stopped in the
  initramfs ("LABEL=cloudimg-rootfs does not exist", "A valid RSDP was not found"). The domain now sets
  `features = { acpi = true, apic = {} }`. Any other default the old provider supplied must likewise be written
  explicitly.
- State is local (single user, lab). A team would use a remote backend with locking.
