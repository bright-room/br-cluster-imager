# br-cluster-imager

project-brightで利用するOSのゴールデンイメージを管理するリポジトリ

本リポジトリではサーバー毎にcloud-configで利用するファイルを生成し、ubuntuイメージ内に取り込まれた形のイメージが作成される

## Architecture

- [docker](https://www.docker.com/ja-jp/)
- [1password connect](https://developer.1password.com/docs/connect/)
- [jinja2](https://jinja.palletsprojects.com/en/stable/)
- [packer](https://www.packer.io/)
  - [packer-builder-arm](https://github.com/mkaczanowski/packer-builder-arm)

## 事前セットアップ

本リポジトリでは1password connectを活用してサーバー情報を取得してファイル生成をしているため、事前にconnect serverの接続に必要なcredentials情報が必須となる
作成方法については[こちら](https://developer.1password.com/docs/connect/get-started)を参照

作成したcredentials情報は以下に格納する  
環境毎に保管庫を分けているためそれぞれディレクトリを用意して確認証ファイルを以下のように配備する。

- 1password-credentials.json
  - `.secret/<dev or prod>/1password-credentials.json`
- Access token
  - `.secret/<dev or prod>/.connect_token`にJWTトークンを貼り付ける

以下のコマンドで1password-connect群のコンテナを起動する

```shell
make bootstrap
```

## cloud-configの作成方法

```shell
# dev環境
make dev/generate-config

# prod環境
make prod/generate-config
```

## cloud-configで利用するファイルを包括したイメージファイルを作成方法

一括でイメージを作成するコマンド

```shell
# dev環境
make dev/image-build

# prod環境
make prod/image-build
```

個別でイメージ作成をするコマンド

```shell
# dev環境
make dev/mage-build/<サーバー識別子>

# prod環境
make prod/mage-build/<サーバー識別子>
```

サーバー一覧
- br-gateway1
- br-gateway2
- br-external1
- br-external2
- br-node1
- br-node2
- br-node3
- br-node4
- br-node5
- br-node6
- br-node7
- br-node8
- br-node9
- br-node10

## Clean

生成したファイルやコンテナ群を削除するには以下のコマンドを実行する

```shell
make clean
```
