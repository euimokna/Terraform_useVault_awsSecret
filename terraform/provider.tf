terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.23.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "2.17.0"
    }
  }
}

provider "vault" {
  # It is strongly recommended to configure this provider through the environment variables described above, so that each user can have
  # separate credentials set in the environment.
  #
  # This will default to using $VAULT_ADDR
  # But can be set explicitly
  # address = "https://vault.example.net:8200"
  address = var.vault_addr
  token = "hvs.Clw6XPSxQLgqJ4iuISeZNZs1"
  
//   auth_login {
//   path = "auth/approle/login"
//   parameters = {
//     role_id   = var.login_approle_role_id
//     secret_id = var.login_approle_secret_id
//   }
//  }
}

# 코드 실행 시 Vault AWS 시크릿 엔진을 사용하여, data 값으로 access_key와 secret_key 생성하여 사용
provider "aws" {
  region     = var.region
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
  # STS Token을 사용하지 않는 경우 주석 처리
  #token      = data.vault_aws_access_credentials.creds.security_token
}

