# 融け切る前に

やらなくちゃいけないことは山ほどあるけど、習慣化は苦手…

そんなお悩みありませんか？

ちょうど開発期間が夏だったので、タスクをかき氷になぞらえました。

設定したタスクを時間内に終えてからモバイル端末を振ると、かき氷機のアニメーションが再生されます！（シロップはタスク設定時に指定した色）

ただし失敗すると亡霊が爆誕…
他のかき氷をランダムで亡霊に変えてしまいます…
これまでの努力がちゃらに…

## 画面遷移
ホーム
<img width="1080" height="2400" alt="ホーム" src="https://github.com/user-attachments/assets/56b1874a-7128-45fb-bc68-44b044529836" />

タスクを設定するとカウントが始まります
<img width="1080" height="2400" alt="タイマー画面" src="https://github.com/user-attachments/assets/cf340c10-a786-4372-b61a-57ffd99401ea" />

完了したらタイマーを止めてかき氷を作ります
端末を振ってみよう！
<img width="1080" height="2400" alt="振ってみよう" src="https://github.com/user-attachments/assets/9a03ae68-7803-4f8c-b9f3-c939be4511bd" />

シェイク中画面
<img width="1080" height="2400" alt="シェイク中" src="https://github.com/user-attachments/assets/6aef948e-4a61-4bcf-8365-6081a06ab779" />

かき氷完成！
<img width="1080" height="2400" alt="かき氷完成" src="https://github.com/user-attachments/assets/0e8e2654-fb04-49de-b67d-1b48e2a93be1" />

完成したかき氷はアルバム画面で確認可能
<img width="1080" height="2400" alt="アルバム（通常）" src="https://github.com/user-attachments/assets/b6e49136-e539-47c3-b616-ed164059b057" />

タスク完了に失敗すると成仏できなかった氷が幽霊になってしまいます…
完了してもらえなかった恨みから、アルバムに表示されている成仏できた他のタスクを破壊してしまいます。運が悪いとすべて幽霊にされてしまうことも…
<img width="1080" height="2400" alt="アルバム（亡霊）" src="https://github.com/user-attachments/assets/20a752cd-477c-4250-8dd5-910fadb5d38e" />

## 技術スタック
フロントエンド：Flutter（モバイル、sdk: ^3.13.1）

(pubepec.yaml dependenciesより)

cupertino_icons: ^1.0.8

flutter_foreground_task: ^11.0.1

sensors_plus: ^7.1.0

supabase_flutter: ^2.6.0

shared_preferences: ^2.5.3

audioplayers: ^6.1.0


バックエンド：Supabase

使用ツール  ：GitHub、VSCode、Android Studio（エミュレータ）、Android実機

### システム構成図
<img width="2526" height="995" alt="かき氷構成図" src="https://github.com/user-attachments/assets/26fdf12b-a85a-41cc-91e8-c5557ebbea51" />

## 分担
[Yuji](https://github.com/Yuji-ctrl): 共同PL、アイディア（亡霊部分）、モブプロでの指導（環境構築から自走するまで）、フロントエンドへのアニメーションの埋め込み、端末振動との連動


[Takumi](https://github.com/takumi-3030): アニメーション素材制作（Flutterへの埋め込み、制御を考えたときに適切な形式を探るのにかなり時間がかかりました、RiveやLottieなど様々試しましたが、最終的にはSVGを採用しました）、アルバム画面、発表


[Ryo](https://github.com/ryperi): フロントエンド基本画面


[Tomoyo](https://github.com/Tomoodi): 共同PL、発案（メインアイディア）、Supabase（フロントとのつなぎ込みまで・初挑戦）、発表








## 開発上の注意（初心者メンバーがいたため分かりやすくここにルールを記載）
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

FlutterのSDKは3.13.~~を使用
アップグレードする場合は
flutter upgrade
他プロジェクトで別のバージョンを使う予定のある人は、別途FVMを入れて複数バージョンをプロジェクトごとに切り替え

使用ライブラリは
pubspec.yaml
のdependenciesに記載
Flutterのルートはこのファイルがある場所

VSCodeはGitのリポジトリ(.gitフォルダのある場所)単位で開く

面倒だが、各言語ごとの実行はcdコマンドでもう一つ潜ってから


