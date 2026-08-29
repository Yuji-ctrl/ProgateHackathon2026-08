---
name: get-started
description: Flutterアプリ(frontend/)の環境準備・起動・基本操作、および最低限のgit操作を初心者向けに説明する。「起動できない」「動かし方が分からない」「セットアップ」「flutter run したい」「gitの使い方」などで呼び出す。
---

# アプリの起動と基本操作

このリポジトリは Flutter アプリ(`frontend/`)+ Supabase(バックエンド)構成。
初めて動かす人向けに、確認 → 案内の順で進める。手元の環境を実際に確認してから答えること(前提で決めつけない)。

## 1. 前提確認

以下を順にコマンドで確認する。

```bash
flutter --version
```

- `frontend/pubspec.yaml` の `environment.sdk` は `^3.13.1`。Flutter SDK が古すぎる場合はここが原因になりやすい。
- Flutter が入っていなければ https://docs.flutter.dev/get-started/install を案内する。

```bash
flutter doctor
```

- Android Studio / Xcode / エミュレータ関連の未設定項目がないか確認させる。

## 2. 依存関係の取得

`frontend/` ディレクトリで実行する(リポジトリルートではない点に注意)。

```bash
cd frontend
flutter pub get
```

エラーが出た場合、まず `flutter --version` が pubspec.yaml の SDK 制約を満たしているか確認する。

## 3. 起動

接続中のデバイス/エミュレータを確認してから起動する。

```bash
flutter devices
flutter run
```

- 複数デバイスがある場合は `flutter run -d <device-id>`。
- 起動中は `r` でホットリロード、`R` でホットリスタート、`q` で終了。
- Windows で Android エミュレータが無い場合は `flutter run -d chrome` でも動作確認できる(Web対応している範囲に限る)。

## 4. Supabase について

`frontend/lib/main.dart` に Supabase の URL/anonKey がすでに埋め込まれているため、追加の `.env` 設定などは不要。バックエンド用の別ディレクトリはまだ存在しない。

## 5. 最低限の git 操作

チーム開発なので、変更前に必ず自分のブランチにいることを確認する。

```bash
git status
git branch          # 今いるブランチを確認
git checkout -b <自分の作業ブランチ名>   # 新しく作業ブランチを作る場合
```

変更ができたら:

```bash
git add <変更したファイル>   # git add . は使わない(意図しないファイルを含めやすい)
git status                    # 何がステージされたか必ず確認
git commit -m "変更内容が分かる短い日本語メッセージ"
git push -u origin <自分の作業ブランチ名>
```

- 直接 `main` / `development` にコミット・pushしない。作業ブランチを切って GitHub 上で Pull Request を作る。
- `git push --force` や `git reset --hard` など元に戻せない操作は、必ず内容を説明してから実行の可否を確認する。

## 6. よくあるつまずき

- `flutter: command not found` → PATH に Flutter SDK の `bin` が通っていない。
- `pub get` が失敗する → ネットワーク or SDKバージョン不一致を疑う。
- 端末/エミュレータが `flutter devices` に出ない → エミュレータを起動してから再実行、または実機のUSBデバッグ設定を確認。
- ビルドは通るが白画面/落ちる → まずターミナルのログ(赤字のエラー)を確認してから原因を特定する。
