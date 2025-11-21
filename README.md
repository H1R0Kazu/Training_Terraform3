# Terraform Training Project

このプロジェクトはTerraformの学習・検証用のリポジトリです。

## ディレクトリ構造

```
.
├── environments/          # 環境別の設定
│   ├── dev/              # 開発環境
│   ├── staging/          # ステージング環境
│   └── prod/             # 本番環境
└── modules/              # 再利用可能なモジュール
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

- Terraform >= 1.0
- AWS CLI (AWSプロバイダーを使用する場合)
- 適切なAWS認証情報の設定
