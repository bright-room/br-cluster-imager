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

- 1password-credentials.json
  - `.secret/1password-credentials.json`
- Access token
  - `.secret/.connect_token`にJWTトークンを貼り付ける

以下のコマンドで1password-connect群のコンテナを起動する

```shell
make pre-setup
```

## cloud-configの作成方法

```shell
make generate-config
```

## cloud-configで利用するファイルを包括したイメージファイルを作成方法

```shell
make image-build/prod/<サーバー識別子>
```

サーバー一覧
- gateway1
- external1
- node1
- node2
- node3
- node4
- node5
- node6

## Clean

生成したファイルやコンテナ群を削除するには以下のコマンドを実行する

```shell
make clean-all
```
