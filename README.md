# Terraform Training Project

このプロジェクトはTerraformの学習・検証用のリポジトリです。

## プロジェクト概要

AWS Managed Prefix Listを使用したセキュリティグループの作成と管理を検証します。特に、新しいリソースタイプ `aws_vpc_security_group_ingress_rule` と `aws_vpc_security_group_egress_rule` を使用したセキュリティグループルールの管理方法を実証します。

### 現在の構成

- **Prefix List**: 5個のエントリー（テスト用IPアドレス範囲）
- **セキュリティグループ**: udemy VPC内に作成
- **Ingressルール**: 3つ（HTTPS/443、HTTP/80、SSH/22）- Prefix Listを参照
- **Egressルール**: 1つ（全てのアウトバウンドトラフィックを許可）
- **リソースタイプ**: AWS Provider 5.0以降の新しいリソースを使用
  - `aws_vpc_security_group_ingress_rule`
  - `aws_vpc_security_group_egress_rule`

### 重要な発見：Prefix List容量制限

**Prefix Listを参照するセキュリティグループの容量計算：**

```
セキュリティグループ容量 = ルール数 × Prefix ListのMaxEntries
```

**検証結果：**
- 現在の構成: 3ルール × 10 MaxEntries = 30容量（問題なし）
- 試行した構成: 3ルール × 50 MaxEntries = 150容量（**失敗**）
- **AWS制限**: セキュリティグループあたり60ルール/容量

Prefix Listの`max_entries`を10から50に増やそうとしたところ、以下のエラーが発生：

```
Error: Unable to modify maximum entries from (10) to (50).
The following VPC Security Group resources do not have sufficient capacity [sg-0b04a69009c80dd71].
```

**結論：** Prefix Listを使用する場合、実際のエントリ数ではなく`max_entries`の値がセキュリティグループの容量に影響する。Prefix Listを参照するルール数と`max_entries`の積がAWSの60ルール制限を超えないよう設計する必要がある。

## ディレクトリ構造

```text
.
├── environments/          # 環境別の設定
│   ├── dev/              # 開発環境
│   ├── staging/          # ステージング環境
│   └── prod/             # 本番環境
├── modules/              # 再利用可能なモジュール
├── README.md             # プロジェクト概要
├── WORK_LOG.md           # 作業記録
└── CLAUDE.md             # Claude Code用ガイダンス
```

## 使い方

### 初期化

```bash
cd environments/dev
terraform init
```

### プランの確認

```bash
terraform plan
```

### リソースの適用

```bash
terraform apply
```

### リソースの削除

```bash
terraform destroy
```

## 必要な環境

- Terraform >= 1.12.2
- AWS Provider ~> 5.0（新しいリソースタイプを使用するため）
- AWS CLI（AWSプロバイダーを使用する場合）
- 適切なAWS認証情報の設定
- 既存のVPC（タグ名: "udemy"）

## 詳細情報

プロジェクトの詳細な作業履歴と技術情報については、以下のファイルを参照してください：

- [WORK_LOG.md](WORK_LOG.md) - 作業記録と実装詳細
- [CLAUDE.md](CLAUDE.md) - Claude Code用のプロジェクトガイダンス
