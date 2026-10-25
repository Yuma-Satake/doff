# doff

macOSで画面だけを消し、システムはスリープさせないコマンド。キーボードかマウスを操作すると、スリープ防止を自動で解除する。左下のホットコーナーからも実行できる。

このREADMEは、別のPCへ導入するAIエージェント向けの手順書。

## 前提

- macOS、シェルはzsh
- `git`と`gh`が使える
- ツールの追加インストールは不要。使うのは`caffeinate`・`pmset`・`ioreg`・`launchctl`・`defaults`などOS標準のコマンドのみ

## 構成

- `doff`: 本体。`pmset displaysleepnow`で画面を消し、`caffeinate -i`でアイドルスリープを防ぐ。`ioreg`の`HIDIdleTime`を1秒ごとに見て、無操作が続いた後に入力があれば`caffeinate`を終了する
- `hot-corner`: 画面保護プログラム(`ScreenSaverEngine`)の起動を監視し、検知したら終了させて`doff`を実行する。ホットコーナーには任意のコマンドを割り当てられないため、この方式を取る
- `io.github.yuma-satake.doff-hot-corner.plist.template`: `hot-corner`を常駐させるLaunchAgentのテンプレート。`__HOME__`を導入時にホームディレクトリへ置換する

スクリプトは`$HOME/.config/doff/`に置かれている前提のパスを持つ。clone先を変えない。

## 導入手順

次の順に実行する。2、4、5はユーザーの環境設定を変更するため、実行前にユーザーへ内容を伝える。

1. cloneする

```sh
git clone https://github.com/Yuma-Satake/doff ~/.config/doff
```

2. LaunchAgentを生成して登録する。既に登録済みの場合は先に`bootout`する

```sh
mkdir -p ~/Library/LaunchAgents ~/Library/Logs
sed "s|__HOME__|$HOME|g" ~/.config/doff/io.github.yuma-satake.doff-hot-corner.plist.template > ~/Library/LaunchAgents/io.github.yuma-satake.doff-hot-corner.plist
launchctl bootout gui/$(id -u)/io.github.yuma-satake.doff-hot-corner 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/io.github.yuma-satake.doff-hot-corner.plist
```

3. 実行権限を確認する(cloneで付いているはず)

```sh
chmod +x ~/.config/doff/doff ~/.config/doff/hot-corner
```

4. 左下のホットコーナーに「画面保護プログラムを開始」を割り当てる。先に現在値を読み、既に別の動作が割り当てられている場合は上書きせずユーザーに確認する

```sh
defaults read com.apple.dock wvous-bl-corner
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0
killall Dock
```

5. `~/.zshrc`にエイリアスを追記する。既に`alias doff=`があれば追記しない

```sh
alias doff="$HOME/.config/doff/doff"
```

## 確認

- `launchctl list | grep doff-hot-corner`に行が出る
- `pgrep -lf doff/hot-corner`でプロセスが動いている
- `doff`や左下のホットコーナーを実際に実行すると画面が消えるため、実行前にユーザーへ伝える。実行後は、キーかマウスを操作して復帰し、`/tmp/display-off-caffeinate.pid`が消えていれば正常

`pgrep -l caffeinate`には、`doff`以外が起動した`caffeinate`も表示される。`doff`由来かどうかは`/tmp/display-off-caffeinate.pid`のPIDで判断し、それ以外は止めない。

## 注意

- ホットコーナーを使う場合、システム設定で画面保護プログラムの起動までの待機時間を設定すると、放置でも画面保護プログラムが起動し、そのたびに`doff`が実行される。待機時間は「なし」のままにする
- ホットコーナーの操作では、画面保護プログラムが監視間隔の分だけ一瞬表示されてから画面が消える
- 復帰の判定はキーボードとマウスの操作のみ。SSHなどの遠隔操作では解除されない。その場合は`kill $(cat /tmp/display-off-caffeinate.pid)`で止める

## 削除

```sh
launchctl bootout gui/$(id -u)/io.github.yuma-satake.doff-hot-corner
rm ~/Library/LaunchAgents/io.github.yuma-satake.doff-hot-corner.plist
defaults delete com.apple.dock wvous-bl-corner
defaults delete com.apple.dock wvous-bl-modifier
killall Dock
```

`~/.zshrc`のエイリアスと`~/.config/doff`も必要に応じて削除する。
