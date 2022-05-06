variable region {
  default="ap-northeast-2"
}

variable "name" { default = "vault-dynamic-creds"}

variable ttl { default = "24h"}

variable "vault_addr" {
  description = "Vault Server address format : http://IP_ADDRES:8200"
  default     = "http://127.0.0.1:8200"
}

// variable login_approle_role_id {
//   description = "AppRole의 Role ID값 설정"
// }
// variable login_approle_secret_id {
//   description = "AppRole의 Secret ID값 설정"
// }
# 
variable aws_sec_path {
  description = "AWS 시크릿 엔진 경로, 마지막은 반드시 '/'로 끝나게 설정."
  default = "aws/"
}

variable aws_sec_role {
  description = "AWS 시크릿 엔진 상의 Role 이름"
  default ="VAULT상에 생성된 AWS시크릿 엔진의 Role이름"
}
