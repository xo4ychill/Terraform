## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | 0.197.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [yandex_vpc_network.develop](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_network) | resource |
| [yandex_vpc_subnet.develop](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_subnet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Название VPC сети | `string` | n/a | yes |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Название подсети | `string` | n/a | yes |
| <a name="input_v4_cidr_blocks"></a> [v4\_cidr\_blocks](#input\_v4\_cidr\_blocks) | CIDR блок для подсети | `list(string)` | <pre>[<br/>  "10.0.1.0/24"<br/>]</pre> | no |
| <a name="input_zone"></a> [zone](#input\_zone) | Зона доступности для подсети | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_id"></a> [network\_id](#output\_network\_id) | ID созданной сети |
| <a name="output_network_name"></a> [network\_name](#output\_network\_name) | Имя сети |
| <a name="output_subnet_cidr_blocks"></a> [subnet\_cidr\_blocks](#output\_subnet\_cidr\_blocks) | CIDR блоки подсети |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | ID созданной подсети |
| <a name="output_subnet_name"></a> [subnet\_name](#output\_subnet\_name) | Имя подсети |
| <a name="output_subnet_zone"></a> [subnet\_zone](#output\_subnet\_zone) | Зона доступности подсети |
