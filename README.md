## kasikari_memo

A new Flutter project.

「Flutter x Firebaseで始めるモバイルアプリ開発」をFlutter 1.26.0で動くように修正

## chapter7変更点

pubspec.yamlに「firebase_core」を追加。「lib/main.dart」でインポートしたのち、main()関数内でFirebaseの初期化処理。

~~~
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
~~~


android/app/bundle.gradleに以下を追記

~~~
  android{
    defaultConfig{
      multiDexEnabled true
      ...
  dependencies{
    implementation 'androidx.multidex:multidex:2.0.1
    ...
~~~


StreamBuilder内のsnapshot.data.documentsを変更

~~~
snapshot.data.docs....
~~~

Firestoreからのタイムスタンプ取得コードを変更

~~~
document['date'].toDate().toString().substring(0, 10)
~~~

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# kasikari_memo

#   f l u t t e r D i c t i o n a r y  
 