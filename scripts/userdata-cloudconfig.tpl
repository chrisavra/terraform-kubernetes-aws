#cloud-config
# Uses cloud-config configuration in place of pure shell scripts (https://cloudinit.readthedocs.io/en/latest/topics/examples.html)
# Can leverage Cloud-init Multipart rendering using Terraform (see https://www.terraform.io/docs/providers/template/d/cloudinit_config.html)

# Update system
package_update: true
repo_upgrade: all

# Apt package management configuration
apt:
  # Sources.list configuration
  preserve_sources_list: true
  sources_list: |
    deb $MIRROR $RELEASE main restricted
    deb-src $MIRROR $RELEASE main restricted
    deb $PRIMARY $RELEASE universe restricted
    deb $SECURITY $RELEASE-security multiverse
  
  # Proxy Configuration
  proxy: http://${proxy}

  sources:
    # Adding latest docker stable version repo for ubuntu
    docker.list:
      source: "deb [arch=amd64] https://download.docker.com/linux/ubuntu $RELEASE stable"
      keyid: 0EBFCD88
    # Adding Google cloud Kubernetes repo
    kubernetes.list:
      source: "deb http://apt.kubernetes.io/ kubernetes-xenial main"
      keyid: BA07F4FB

  # Installing Packages  
  packages:
  - docker-ce
  - awscli
  - jq
  - zip
  - cntlm
  - chrony

# Static files
write_files:
  - path: /etc/terraform/s3_bucket
    content: |
      ${s3_id}
  - path: /etc/terraform/role
    content: |
      ${role}
  - path: /etc/terraform/volume
    content: |
      ${volume}
  - path: /etc/terraform/load_balancer_dns
    content: |
      ${load_balancer_dns}

# Add ubuntu to docker group
groups:
  - docker: [ubuntu]

runcmd:
  - [/bin/echo, "server 169.254.169.123 prefer iburst", >>, /etc/chrony.conf ]
  - [/bin/systemctl, restart, chrony]
  - [/bin/systemctl, enable, chrony]
  - dig +short ${load_balancer_dns} | head -1 > /etc/terraform/load_balancer_ip
