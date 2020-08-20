# Qiitaに書いた記事をGitHub用にダウンロードするスクリプト


## 概要

Qiitaに投稿した記事を、GitHub用にダウンロードします。Qiitaからデータを取ってくるスクリプトと、取ってきたデータを見てローカルデータを更新するスクリプトの２つがあります。


* `qiita_get.rb` Qiitaからデータを取ってくるRubyスクリプトです。中身の`$USER`をご自身のIDに変えて使ってください。アクセストークンを`QIITA_TOKEN`という名前の環境変数で与えておく必要があります。実行すると、`qiita.yaml`というファイルを作ります。また、デバッグ用に`qiita?.json`というファイルも吐きます。
* `sync.rb` `qiita.yaml`とローカルファイルの状況を見て、ローカルファイルの更新をします。記事とディレクトリの関係は`dirlist.yaml`というYAMLファイルで指定します。このファイルは初回実行次に作成されます。

## 使い方

まずデータを取ってきます。

```sh
ruby qiita_get.rb
```

次に、syncスクリプトを走らせます。

```sh
ruby sync.rb
```

このファイルは、`dirlist.yaml`というYAMLファイルを見て、記事のタイトルとディレクトリを関連付けます。このファイルが無ければ初回実行時に作られます。こんなファイルになります。

```yaml
---
Pythonでフーリエ変換:
822823回マクロを展開するとGCCが死ぬ:
WindowsのVSCodeで__m256d型のインデックスアクセスにenumを使うと怒られる:
```

このタイトルのところにディレクトリ名を指定すると、そのディレクトリに記事を展開します。例えば「Pythonでフーリエ変換」という記事を`python_fft`というディレクトリに保存したいなら

```yaml
---
Pythonでフーリエ変換: python_fft
822823回マクロを展開するとGCCが死ぬ:
WindowsのVSCodeで__m256d型のインデックスアクセスにenumを使うと怒られる:
```

とします。この状態で`sync.rb`を実行してみます。

```sh
$ ruby sync.rb
Create direcotry python_fft
https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/79744/1551cc23-899c-089b-2335-1ab9700008f3.png
.png
(snip)
4-f517-bea7-4bba14ff5a37.png to python_fft/image13.png
Updated 1 article(s).
```

ディレクトリが無ければ作り、あれば`README.md`のタイムスタンプと記事のタイムスタンプを比較し、古ければ上書きします。イメージは「image?.拡張子」という名前でダウンロードします。

以後、`qiita_get.rb`、`sync.rb`を実行すれば差分を更新してくれるはずです。

## ライセンス

MIT
