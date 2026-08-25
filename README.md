# ProgateHackathon2026-08

**【開発上の注意】**
Gitのブランチが機能名になっているかを確認（VSCodeだと一見わからないが、直接developmentやmainで作業しない！！！）
機能の開発が終わったらリモートリポジトリのイシューを閉じてブランチは乗り捨てる（消すかどうかはチームの運用による、今回はポートフォリオにする人もいるので残す？）
古いブランチは現在との差分が大きくなっているので使わない！！！
開発は機能ブランチで、変更はその都度developmentブランチへ
最終的にdevelopmentの内容をmainに上書きするかすげ替えるか


基本は
flutter run
でOK

flutter build（全部作り直し）、flutter install（最終）
リポジトリのルートと言語・フレームワークごとのルートは違うので注意
Flutterのルートはpubspec.yamlのあるところ

他の人の変更を取得したらすぐに
flutter pub get
（pubspec.yamlのdependenciesをもとにライブラリの中身をインストール）

いじるところは基本的にlibフォルダ（画面）、android/app/src/main/AndroidManifest.xml（Android OSの権限周り）

Android Studioとエミュレータ、または実機を起動・接続（USB線でつなぐまたはワイヤレスデバッグ）しておく
実機の場合開発者モードをオンにする

.gitignoreにはGitに乗せないファイル一覧を相対PATHで記述（ビルド生成物、セキュリティ関連データなど）
一度Gitに乗せてしまったものは「基本的は」消せないので新しい大事なファイルを追加する際にはignoreすべきかを確認

ターミナルはフロントとバック両方で別々に立てる
それぞれでルートに潜って実行
