# 作業記録 - Prefix ListとSecurity Groupの作成

## プロジェクト概要

このプロジェクトはTerraformの学習・検証用リポジトリで、AWS Prefix Listを使用したセキュリティグループの作成を検証します。特に、AWS Provider 5.0以降で導入された新しいリソースタイプ `aws_vpc_security_group_ingress_rule` と `aws_vpc_security_group_egress_rule` を使用します。

## 環境情報

- **Terraformバージョン**: 1.12.2
- **AWS Providerバージョン**: ~> 5.0
- **AWSリージョン**: ap-northeast-1（東京）
- **使用VPC**: udemy
- **環境**: dev（開発環境）

## 作業履歴

### 1. Prefix Listの作成

AWS Managed Prefix Listを作成し、5つのテスト用IPアドレス範囲を登録。

**設定内容:**
- 名前: `test-miyata-prefix-list`
- アドレスファミリー: IPv4
- 最大エントリ数: 10
- エントリー数: 5つ

**登録エントリ:**

1. `10.0.1.0/24` - Office A
2. `10.0.2.0/24` - Office B
3. `192.168.1.0/24` - VPN Connection
4. `172.16.0.0/24` - Remote Work
5. `203.0.113.0/24` - Partner Company (Test IP)

### 2. ファイル構造の整理

main.tfを役割ごとに分割し、管理しやすい構造に変更。

**ファイル構成:**

```text
environments/dev/
├── terraform.tf        # Terraformブロック（バージョン、プロバイダー定義）
├── provider.tf         # AWSプロバイダー設定
├── variables.tf        # 変数定義
├── locals.tf          # ローカル変数（Prefix Listエントリー、SGルール定義）
├── data.tf            # データソース（Udemy VPC）
├── main.tf            # Prefix Listリソース定義
├── security_group.tf  # セキュリティグループとルール定義
└── outputs.tf         # 出力定義
```

### 3. セキュリティグループの作成

Prefix Listを参照するセキュリティグループを作成。

**設定内容:**
- 名前: `test-sg-with-prefix-list`
- VPC: udemy VPC（既存）
- Ingressルール（3つ、Prefix Listを参照）:
  - HTTPS (443/tcp)
  - HTTP (80/tcp)
  - SSH (22/tcp)
- Egressルール: 全てのアウトバウンドトラフィックを許可

**実装の特徴:**
- `for_each`を使用してIngressルールを動的に生成
- ルール定義はlocals.tfで一元管理
- Prefix List IDを参照することで、IPアドレス範囲の変更が容易

### 4. 新しいリソースタイプへの移行

AWS Provider 5.0以降で推奨される新しいリソースタイプに変更。

**変更内容:**
- `aws_security_group_rule` → `aws_vpc_security_group_ingress_rule` / `aws_vpc_security_group_egress_rule`
- セキュリティグループ本体とルールを完全に分離
- インラインルールではなく、独立したリソースとして管理

**新しいリソースの特徴:**
- `protocol` → `ip_protocol`
- `prefix_list_ids` (複数形) → `prefix_list_id` (単数形)
- `cidr_blocks` → `cidr_ipv4`
- `from_port`/`to_port` は引き続き使用可能

## 主要なTerraformコード

### Prefix List定義（locals.tf）

```hcl
locals {
  prefix_list_entries = [
    {
      cidr        = "10.0.1.0/24"
      description = "Office A"
    },
    {
      cidr        = "10.0.2.0/24"
      description = "Office B"
    },
    {
      cidr        = "192.168.1.0/24"
      description = "VPN Connection"
    },
    {
      cidr        = "172.16.0.0/24"
      description = "Remote Work"
    },
    {
      cidr        = "203.0.113.0/24"
      description = "Partner Company (Test IP)"
    }
  ]

  # Security Group Ingress Rules
  security_group_ingress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS from prefix list IPs"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP from prefix list IPs"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH from prefix list IPs"
    }
  ]
}
```

### Prefix Listリソース（main.tf）

```hcl
resource "aws_ec2_managed_prefix_list" "test_miyata" {
  name           = "test-miyata-prefix-list"
  address_family = "IPv4"
  max_entries    = 10

  dynamic "entry" {
    for_each = local.prefix_list_entries
    content {
      cidr        = entry.value.cidr
      description = entry.value.description
    }
  }

  tags = {
    Name = "test-miyata-prefix-list"
  }
}
```

### セキュリティグループとルール（security_group.tf）

```hcl
# Security Group using Prefix List
resource "aws_security_group" "test_with_prefix_list" {
  name        = "test-sg-with-prefix-list"
  description = "Security group using managed prefix list for testing"
  vpc_id      = data.aws_vpc.udemy.id

  tags = {
    Name = "test-sg-with-prefix-list"
  }
}

# Ingress rules from Prefix List (using aws_vpc_security_group_ingress_rule)
resource "aws_vpc_security_group_ingress_rule" "from_prefix_list" {
  for_each = { for idx, rule in local.security_group_ingress_rules : idx => rule }

  security_group_id = aws_security_group.test_with_prefix_list.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  prefix_list_id    = aws_ec2_managed_prefix_list.test_miyata.id
  description       = each.value.description
}

# Egress rule: Allow all outbound traffic (using aws_vpc_security_group_egress_rule)
resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.test_with_prefix_list.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}
```

## 実行手順

### 1. 初期化

```bash
cd environments/dev
terraform init
```

### 2. Prefix Listとセキュリティグループの作成

```bash
terraform plan
terraform apply
```

## 出力情報

`terraform apply`実行後、以下の情報が出力されます:

- `prefix_list_id`: Prefix ListのID
- `prefix_list_arn`: Prefix ListのARN
- `security_group_id`: セキュリティグループのID
- `vpc_id`: udemy VPCのID
- `aws_region`: 使用しているAWSリージョン
- `environment`: 環境名（dev）

## GitHubリポジトリ

- **URL**: https://github.com/H1R0Kazu/Training_Terraform3
- **ブランチ**: main

### コミット履歴

1. `fe22c7e` - Initial commit: Add Terraform project with AWS Prefix List
2. `7ebbd66` - セキュリティグループをPrefix Listで作成（現在地）

### 5. 新リソースタイプへの実際の移行作業（2025-11-21）

AWS Provider 5.0+の新しいリソースタイプへの移行を実施しました。

#### 作業手順

**ステップ1: 既存ルールの削除**

`security_group.tf`から旧リソースタイプの定義を削除し、terraform applyを実行。

```bash
terraform plan   # 4つのルール削除を確認
terraform apply  # 実行
```

削除されたリソース（旧タイプ）:
- `aws_security_group_rule.egress_all` - ID: sgrule-235794544
- `aws_security_group_rule.ingress_from_prefix_list["0"]` - ID: sgrule-2363168827 (HTTPS/443)
- `aws_security_group_rule.ingress_from_prefix_list["1"]` - ID: sgrule-1817352344 (HTTP/80)
- `aws_security_group_rule.ingress_from_prefix_list["2"]` - ID: sgrule-3984986704 (SSH/22)

実行結果: `0 added, 0 changed, 4 destroyed`

**ステップ2: 新リソースタイプでの再作成**

`security_group.tf`に新リソースタイプの定義を追加し、terraform applyを実行。

```bash
terraform plan   # 4つのルール追加を確認
terraform apply  # 実行
```

作成されたリソース（新タイプ）:
- `aws_vpc_security_group_egress_rule.allow_all` - ID: sgr-0d3e635e3980a0033
- `aws_vpc_security_group_ingress_rule.from_prefix_list["0"]` - ID: sgr-0ef793c82f0c0df96 (HTTPS/443)
- `aws_vpc_security_group_ingress_rule.from_prefix_list["1"]` - ID: sgr-011fb2caf33e7dd1b (HTTP/80)
- `aws_vpc_security_group_ingress_rule.from_prefix_list["2"]` - ID: sgr-07a27dcf3d05111a7 (SSH/22)

実行結果: `4 added, 0 changed, 0 destroyed`

#### 移行のポイント

- セキュリティグループ本体（`sg-0b04a69009c80dd71`）は変更なし
- ルールのみを削除→再作成することで、無停止での移行が可能
- 新リソースタイプでは、リソースID形式が `sgrule-*` から `sgr-*` に変更
- デフォルトタグ（Environment, ManagedBy, Project）が自動適用

#### 現在のリソースID一覧

**AWS リソース:**
- Prefix List: `pl-026264adbef1f2da0`
- Security Group: `sg-0b04a69009c80dd71`
- VPC: `vpc-026cf542cccbb039e`

**セキュリティグループルール:**
- Egress (All): `sgr-0d3e635e3980a0033`
- Ingress (HTTPS/443): `sgr-0ef793c82f0c0df96`
- Ingress (HTTP/80): `sgr-011fb2caf33e7dd1b`
- Ingress (SSH/22): `sgr-07a27dcf3d05111a7`

## 今後の拡張案

- [ ] 他の環境（staging, prod）への展開
- [ ] モジュール化して再利用可能にする
- [ ] Prefix Listエントリーの追加・削除の検証
- [ ] セキュリティグループを使用したEC2インスタンスの起動
- [ ] 複数のセキュリティグループでPrefix Listを共有する構成の検証
- [ ] セキュリティグループルール数の上限（60）を超える検証
- [x] AWS Provider 5.0+の新リソースタイプへの移行完了

## 備考

### 新しいリソースタイプの利点

- **より明確な意図**: Ingressルールとegressルールを明示的に分離
- **将来性**: AWS Provider 5.0以降で推奨されるベストプラクティス
- **混在回避**: インラインルールと独立リソースの混在を防ぐ

### その他の利点

- Prefix Listを使用することで、複数のセキュリティグループで同じIPアドレス範囲を簡単に共有できる
- IPアドレス範囲の変更はPrefix Listのみを更新すれば、参照しているすべてのセキュリティグループに反映される
- `for_each`と`dynamic`ブロックを活用することで、コードの重複を避け、保守性が向上
