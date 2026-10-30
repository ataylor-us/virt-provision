# virt-provision

Opentofu (Terraform) IaC for deploying VMs

+ `main.tf` standardizes on Debian 13 VMs on [virt-infra](https://github.com/ataylor-us/virt-infra)
+ `haos.tf` is my [Home Assistant Operating System](https://developers.home-assistant.io/docs/operating-system/) VM, migrated from another box.

```bash
direnv allow
tofu init
tofu plan
tofu apply
```

Secrets come from `pass` via `.envrc`, which is loaded using [direnv](https://github.com/direnv/direnv).
