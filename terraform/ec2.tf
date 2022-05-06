data "vault_aws_access_credentials" "creds" {
  # AWS 시크릿 엔진 경로 : 기본은 AWS
  backend = var.aws_sec_path
  # AWS 시크릿 엔진 구성 시 사용한  Role 이름
  role    = var.aws_sec_role
  #STS Token으로 발급받아 설정. 아닌 경우, 다음 코드를 주석 처리 후 실행할 것.
  # type ="sts"
}

# AMI 정보 조회
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create AWS EC2 Instance
resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.nano"

  tags = {
    Name  = var.name
    TTL   = var.ttl
    owner = "${var.name}-guide"
  }
}
