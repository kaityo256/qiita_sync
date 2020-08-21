# Qiitaに書いた記事をGitHub用にダウンロードするスクリプト

## 概要

Qiitaに投稿した記事を、GitHub用にダウンロードしてSyncします。Qiitaからデータを取ってくるスクリプトと、取ってきたデータを見てローカルデータを更新するスクリプトの２つがあります。

* `qiita_get.rb` Qiitaからデータを取ってくるRubyスクリプトです。Qiitaのユーザ名を`QIITA?USER`、アクセストークンを`QIITA_TOKEN`という名前の環境変数で与えておく必要があります。実行すると、`qiita.yaml`というファイルを作ります。また、デバッグ用に`qiita?.json`というファイルも吐きます。
* `sync.rb` `qiita.yaml`、`dirlist.yaml`を参照し、ローカルファイルの更新をします。

## 使い方

まず、Qiitaのアクセストークンを取得します。[Qiitaの設定のアプリケーション](https://qiita.com/settings/applications)の「個人用アクセストークン」のところで「新しくトークンを発行する」をクリックします。読み込みしかしないので、スコープはread_qiitaだけで良いです。発行したトークンは、その場でしか閲覧できないのでどこかに保存しておきましょう。

次に、環境変数を設定します。Qiitaのユーザ名と、先程取得したアクセストークンを、それぞれ`QIITA_USER`と`QIITA_TOKEN`という名前の環境変数にします。

```sh
export QIITA_USER=kaityo256
export QIITA_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

2つの環境変数を設定した状態で、Qiitaのデータを取得したいディレクトリにて`qiita_get.rb`を実行します。

```sh
mkdir qiita
cd qiita
ruby qiita_get.rb
```

すると、Qiitaの「全データ」が`qiita.yaml`というファイルに保存されます。なお、100本以上の記事がある場合は何回かにわけて保存します。QiitaのAPIにクエリを投げ、取得したJSONデータを`qiita?.json`というファイルに保存します。そのうち後で使うデータ(title, body, created_at, updated_at)だけが`qiita.yaml`に保存されています。

次に、syncスクリプトを走らせます。

```sh
ruby sync.rb
```

このファイルは、`dirlist.yaml`というYAMLファイルを見て、記事のタイトルとディレクトリを関連付けます。もしファイルが無ければ初回実行時に作られます。こんなファイルになります。

```yaml
---
Pythonでフーリエ変換:
822823回マクロを展開するとGCCが死ぬ:
WindowsのVSCodeで__m256d型のインデックスアクセスにenumを使うと怒られる:
```

これはタイトルとディレクトリを結びつけるハッシュです。そこでディレクトリ名を指定すると、そのディレクトリに記事を展開します。例えば「Pythonでフーリエ変換」という記事を`python_fft`というディレクトリに保存したいなら

```yaml
---
Pythonでフーリエ変換: python_fft
822823回マクロを展開するとGCCが死ぬ:
WindowsのVSCodeで__m256d型のインデックスアクセスにenumを使うと怒られる:
```

とします。この状態でもう一度`sync.rb`を実行してみます。

```sh
$ ruby sync.rb
Create direcotry python_fft
https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/79744/1551cc23-899c-089b-2335-1ab9700008f3.png
.png
(snip)
4-f517-bea7-4bba14ff5a37.png to python_fft/image13.png
Updated 1 article(s).
```

ディレクトリが無ければ作り、あれば`README.md`のタイムスタンプと記事のタイムスタンプを比較し、古ければ上書きします。イメージは「image?.拡張子」という名前でダウンロードします。記事名にディレクトリが指定されていなければ無視されますので、一つ一つ指定しては`sync.rb`を走らせてみると良いと思います。

以後、`qiita_get.rb`、`sync.rb`を実行すれば差分を更新してくれるはずです。

## QiitaのMarkdownからの変換

MarkdownのQiita方言とGitHub方言はやや違います。それらを完全に吸収するわけではないのですが、少しだけ変換して保存します。

### 見出しの変換

Qiitaでは

```md
# 節1
...
# 節2
...
```

のように、レベル1の見出しを並べるのが一般的だと思います(多分)。しかしこのままでは、markdownlintが怒るのと、記事のタイトルを入れたいので、

```md
# タイトル
...
## 節1
...
## 節2
...
```

のように、レベル1でタイトル、残りは一個ずつレベルを下げます。

### 画像の変換

Qiitaでは、アップロードされた画像は`amazonaws.com`に保存されますが、その際に

```md
![sample1.png](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/79744/ee833403-b932-4680-aa1b-3bf37084f40b.png)
```

のようにMarkdown形式で保存される場合と、

```html
<img width="229" alt="group1.png" src="https://qiita-image-store.s3.amazonaws.com/0/79744/c98735c4-e967-1fa3-68b9-5a427be5fbf0.png">
```

のようにimgタグを使う場合があります。imgタグの場合にはサイズが指定されているので、それを保存するか迷ったのですが、ここではどちらもファイルをローカルにダウンロードしてMarkdown形式で保存しています。この際、`image1.png`のように、`image`+連番のファイル名で保存します。

### 数式の変換

数式は、`math`で指定されたものを`$$`に変換します。さらに`\begin{align}`を`\begin{aligned}`に変換します。これは私がVSCodeのプレビューでそっちを使っている都合です。

それ以外は全く変換しないので、凝ったこと(表とか)をしているとバグるかもしれません。ご利用は自己責任でどうぞ。

## ライセンス

MIT
