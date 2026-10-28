# virt-provision

Opentofu (Terraform) IaC for deploying Debian 13 VMs on [virt-infra](https://github.com/ataylor-us/virt-infra)

```bash
tofu init
tofu plan
tofu apply
```

Secrets come from `pass` via `.envrc`, which is loaded using [direnv](https://github.com/direnv/direnv).

VMs are declared in `locals.vms` in `main.tf`.

