# virt-provision

Opentofu (Terraform) IaC for deploying VMs on [virt-infra](https://github.com/ataylor-us/virt-infra)

+ `main.tf` is the bulk of my VMs, which include migrated VMs. New VMs default to Debian 13
+ `haos.tf` is my [Home Assistant Operating System](https://developers.home-assistant.io/docs/operating-system/) VM, migrated from another box.
+ `hive.tf` is my puppet/OpenVox server VM, migrated from another box.

```bash
direnv allow
tofu init
tofu plan
tofu apply
```

Secrets come from `pass` via `.envrc`, which is loaded using [direnv](https://github.com/direnv/direnv).

## Versions

[Renovate](https://github.com/renovatebot/renovate) is used to make PRs for [dmacvicar/libvirt](https://github.com/dmacvicar/terraform-provider-libvirt).
