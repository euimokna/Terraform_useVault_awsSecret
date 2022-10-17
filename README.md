# Terraform에서 사용하는 aws secret정보를 vault를 통해 발급하는 데모
- 사전 요구사항 : AWS 계정 (root계정X) 과 access_key , secret key 
- 참고URL 및 Terraform code출처 
><https://docmoa.github.io/04-HashiCorp/06-Vault/04-UseCase/terraform-with-aws-secret-engine.html>  

## vault설치 및 시작 (vagrant환경)
- vagrant설정 파일 
```
# -*- mode: ruby -*-
# vi: set ft=ruby :

centos_image = "centos/7" 
centos_version = "2004.01"

Vagrant.configure("2") do |config|
 
  config.vm.define "VaultServer" do |cent| 
	  cent.vm.provider "virtualbox" do |vb|
	    vb.name = "VaultServer"
        vb.memory = 4096
        vb.cpus = 2    
	  end
	  cent.vm.box = centos_image
	  cent.vm.box_version = centos_version
	  cent.vm.hostname = "VaultServer"
	  cent.vm.network "private_network", ip: "192.168.56.100"
      cent.vm.network "forwarded_port", guest: 22, host: 10100
	  cent.vm.network "public_network",
	    use_dhcp_assigned_default_route: true
      cent.vm.provision "shell", path: "vault_install.sh"
  end
end
```

- vault설치 및 시작 bash shell script
```vault_install.sh
sudo yum install -y yum-utils nc net-tools
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install vault-enterprise
sudo mkdir -p /var/lib/vault/{data,plugins}
sudo chown -R vault:vault /var/lib/vault
sudo cp /vagrant/vault.hclic /etc/vault.d
sudo cat <<EOCONFIG > /etc/vault.d/vault.hcl
ui = true
storage "file" {
  path    = "/var/lib/vault/data"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
disable_mlock = true
default_lease_ttl = "768h"
max_lease_ttl = "768h"
api_addr = "http://127.0.0.1:8200"
plugin_directory = "/var/lib/vault/plugins"
license_path = "/etc/vault.d/vault.hclic" #Vault Enterprise경우에만 필요 
EOCONFIG

sudo systemctl enable vault
sudo systemctl start vault

# Vault Unseal
while( ! nc -z 127.0.0.1 8200 ); do echo "wait Vault service"; sleep 3; done

export VAULT_ADDR=http://127.0.0.1:8200
vault operator init -key-shares=1 -key-threshold=1 > token.txt 

export VAULT_SKIP_VERIFY=True
export VAULT_TOKEN=$(grep 'Initial Root Token:' token.txt | awk '{print $NF}')

vault status
if [ "$?" -eq 2 ]; then
  vault operator unseal $(grep 'Key 1:' token.txt | awk '{print $NF}')
fi
```
## vault aws관련 설정 
- aws 시크릿엔진 enable 
```
vault secrets enable aws
```
- Vault에서 AWS와 통신하기 위한 자격증명 설정
```
vault write aws/config/root \
    access_key=AKxxxxxxx \
    secret_key=xxxxxxxxxxxxxxxxxxxxx \
    region=ap-northeast-2
```
- my-role에 부여할 aws-iam정책 작성
```
vault write aws/roles/my-role \
    credential_type=iam_user \
    policy_document=-<<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:GetUser",
            "Resource": "*"
        }        
    ]
}
EOF
```

## vault AppRole관련 설정(테스트중) - optional : terraform vm에 vault agent가 설치되어야 하는지..? 
- approle엔진 활성화 
```
vault auth enable approle
```
- role생성 
```
vault write auth/approle/role/my-role \
    secret_id_ttl=10m \
    token_num_uses=10 \
    token_ttl=20m \
    token_max_ttl=30m \
    secret_id_num_uses=40
```
- role id 확인 
```
vault read auth/approle/role/my-role/role-id
Key        Value
---        -----
role_id    d3ce0565-a56d-2882-381c-181e1389a6ff
```

- secreteID확인
``` 
vault write -f auth/approle/role/my-role/secret-id
Key                   Value
---                   -----
secret_id             c90d37b2-4d47-cbff-6827-92c37a91b454
secret_id_accessor    1bc3fc89-3248-203d-3a66-481c6f9d8b0e
secret_id_ttl         10m
```
