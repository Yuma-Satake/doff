# doff

macOSで画面だけを消し、システムはスリープさせないコマンド。キーボードかマウスを操作すると、スリープ防止を自動で解除する。左下のホットコーナーからも実行できる。

このREADMEは、別のPCへ導入するAIエージェント向けの手順書。

## 前提

- macOS、シェルはzsh
- `git`が使える
- ツールの追加インストールは不要。使うのは`caffeinate`・`pmset`・`ioreg`・`launchctl`・`defaults`などOS標準のコマンドのみ

## 構成

- `doff`: 本体。`pmset displaysleepnow`で画面を消し、`caffeinate -i`でアイドルスリープを防ぐ。`ioreg`の`HIDIdleTime`を1秒ごとに見て、無操作が続いた後に入力があれば`caffeinate`を終了する
- `hot-corner`: ホットコーナーの「画面保護プログラムを開始」を`Dock`が通知した時にシステムログへ出す`com.apple.screensaver.action`を`log stream`で待ち受け、検知したら`doff`を実行する。ホットコーナーには任意のコマンドを割り当てられないため、この方式を取る。画面保護プログラムは`ScreenSaverEngine`のプロセスではなく`WallpaperAgent`が表示するため、プロセスの有無では検知できない
- `install`: LaunchAgentの生成と登録、左下のホットコーナーの設定を行う。何度実行しても同じ結果になる
- `init.zsh`: `.zshrc`から読み込むファイル。`doff`のエイリアスを定義し、未インストールなら`install`を実行する
- `io.github.yuma-satake.doff-hot-corner.plist.template`: `hot-corner`を常駐させるLaunchAgentのテンプレート。`install`が`__HOME__`をホームディレクトリへ置換して登録する

スクリプトは`$HOME/.config/doff/`に置かれている前提のパスを持つ。clone先を変えない。

## 導入手順

導入はLaunchAgentの登録とDockの設定変更を伴うため、実行前にユーザーへ内容を伝える。

1. cloneする

```sh
git clone https://github.com/Yuma-Satake/doff ~/.config/doff
```

2. `~/.zshrc`に次の1行を追記する。既に同じ行があれば追記しない

```sh
source "$HOME/.config/doff/init.zsh"
```

3. インストールを実行する。新しいシェルを開いても、未インストールであれば`init.zsh`が同じ処理を行う

```sh
~/.config/doff/install
```

`install`は、左下のホットコーナーに既に別の動作が割り当てられている場合は上書きせず、警告を出して終了する。その場合はユーザーに確認する。

## 確認

- `launchctl list | grep doff-hot-corner`に行が出る
- `pgrep -lf doff/hot-corner`でプロセスが動いている
- `doff`や左下のホットコーナーを実際に実行すると画面が消えるため、実行前にユーザーへ伝える。実行後は、キーかマウスを操作して復帰し、`/tmp/display-off-caffeinate.pid`が消えていれば正常

`pgrep -l caffeinate`には、`doff`以外が起動した`caffeinate`も表示される。`doff`由来かどうかは`/tmp/display-off-caffeinate.pid`のPIDで判断し、それ以外は止めない。

## 注意

- ホットコーナーを使う場合、システム設定で画面保護プログラムの起動までの待機時間を設定すると、放置でも画面保護プログラムが起動し、そのたびに`doff`が実行される。待機時間は「なし」のままにする
- ホットコーナーの操作では、画面保護プログラムが一瞬表示されてから画面が消える。画面保護プログラム自体は終了させず、復帰時の入力で解除される。画面保護プログラム後にパスワードを求める設定の場合は、復帰時にパスワードの入力が必要になる
- 復帰の判定はキーボードとマウスの操作のみ。SSHなどの遠隔操作では解除されない。その場合は`kill $(cat /tmp/display-off-caffeinate.pid)`で止める

## 削除

```sh
launchctl bootout gui/$(id -u)/io.github.yuma-satake.doff-hot-corner
rm ~/Library/LaunchAgents/io.github.yuma-satake.doff-hot-corner.plist
defaults delete com.apple.dock wvous-bl-corner
defaults delete com.apple.dock wvous-bl-modifier
killall Dock
```

`~/.zshrc`の`source`行と`~/.config/doff`も削除する。
