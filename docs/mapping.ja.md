# Dart → Go 変換ルール

**Languages:** [English](./mapping.md) | 日本語

変換ルールを決めたらここに記録すること。

## v0.1 最小変換（決定・実装済み）

対象範囲：トップレベルの `void main()` 単体、`int` 型ローカル変数、
`while (true)`、`print(...)`、`sleep(Duration(...))`
（`HANDOFF_dart2tinygo.md` §7 タスク2）。
`packages/dart2tinygo/lib/src/backend/generator.dart` に実装済み。

| Dart | Go |
| --- | --- |
| `void main() { ... }` | `func main() { ... }` |
| `T name(<引数>) { ... }` / `T name(<引数>) => expr;` | `func name(<引数>) T { ... }` — 下の「トップレベル関数」を参照 |
| `return expr;` / `return;` | `return expr` / `return` |
| `var x = <int リテラル>;` | `x := <int リテラル>` |
| `while (true) { ... }` | `for { ... }`（一般の `while (cond)` は `for cond { ... }`） |
| `for (var i = <初期値>; cond; updater) { ... }` | `for i := <初期値>; cond; updater { ... }` — そのまま対応。宣言する変数1つ、条件1つ、updater1つに限定（Go の post-clause は単一の文のため） |
| `break` / `continue` | `break` / `continue` — ラベルなしのみ |
| `x++` / `x--` | `x++` / `x--`（int のみ） |
| `x += y` / `x -= y` / `x *= y` | Go でも同じ記号。`x`/`y` は同じ型（`int` か `double`）でなければならない |
| `a + b` / `a - b` / `a * b` | Go でも同じ記号。`x`/`y` は同じ型（`int` か `double`。混在不可） |
| `a ~/ b` | `a / b` — Go の `int` の除算は既に 0 方向への切り捨てなので、Dart の `~/` と一致する。`int` のみ |
| `a % b` | `dartrt.Mod(a, b)` — Dart の `%` は負にならない（`-5 % 3 == 1`）。Go の `%` は被除数の符号を保つ（`-5 % 3 == -2`）ので、そのまま `%` を出すと負の被除数で結果が違ってしまう。`int` のみ |
| `a / b` | `a / b`。`double` のみ — Dart の `/` は int 同士でも常に `double` を返すため、生成器がキャストなしにそれを再現できない。先に `.toDouble()` で変換する |
| `-a`（単項） | `-a`。`int` か `double` |
| `x ~/= y` | `x /= y`。`int` のみ |
| `x %= y` | `x = dartrt.Mod(x, y)` — `%` と同じ理由。`for` ループの updater としても有効。`int` のみ |
| `x /= y` | `x /= y`。`x`（と `y`）は `double` でなければならない — `/` と同じ理由。`int` の `i` に対する `i /= 2;` はそもそも有効な Dart ではない（`i` の推論型が `double` になってしまう）ので、未対応構文以前の問題。切り捨て除算は `~/=` を使う |
| `x.toDouble()`（`x`: `int`） | `float64(x)` |
| `x.toInt()`（`x`: `double`） | `int(x)` — Go 自身の `int` 変換と同じく 0 方向への切り捨て |
| `x.round()`（`x`: `double`） | `int(math.Round(x))` — 0 から離れる方向への四捨五入。Dart の `double.round()` と一致 |
| `print(<文字列>)` | `println(<文字列>)` — `fmt.Println` ではない（TinyGo で `fmt` を巻き込まないため） |
| `print('... $x ...')` | 文字列連結：`"... " + strconv.Itoa(x) + " ..."` |
| `sleep(Duration(milliseconds: n))` | `time.Sleep(n * time.Millisecond)`（`seconds`/`minutes`/`hours`/`days`/`microseconds` にも対応。複数指定時は加算） |
| `if (cond) { ... } else if (cond2) { ... } else { ... }` | `if cond { ... } else if cond2 { ... } else { ... }` — そのまま対応、同じ形。各分岐は必ず `{ ... }` ブロック |
| `a == b` / `a != b` / `a < b` / `a <= b` / `a > b` / `a >= b` | Go でも同じ記号。両辺は同じ型でなければならない（`int`/`double` の暗黙変換はしない）。`<`/`<=`/`>`/`>=` はさらに `int`/`double` に限定 |
| `a && b` / `a \|\| b` / `!a` | Go でも同じ記号。オペランドは `bool` |
| `(expr)` | `(expr)` — 括弧はそのまま出力 |

生成コードで実際に使う場合のみ Go の import（`strconv`、`time`）を出力する。

## トップレベル関数（2026-09-22 決定、実装済み）

`main` 以外のトップレベル関数はいくつでも、同じ生成ファイル内の Go `func` に 1:1 で
対応する。ソース順に出力する（純粋に差分を読みやすくするためで、Go 自身は宣言順を
気にしないので、前方参照も再帰も制限なく動く）。

- **引数は位置引数のみ。** 名前付き引数（`{required int x}`）、省略可能な位置引数
  （`[int x = 0]`）、デフォルト値はすべて拒否する — Go に相当するものがないため。
  名前付き引数を構造体で表現する方法は将来検討するかもしれない。
- **引数・戻り値の型**：`int`/`double`/`bool`/`String`/`List<int>`/`@GoType`、
  戻り値は `void` も可。他の箇所と同じ「キャストなし」原則が適用されるので、
  関数呼び出し自体は引数をキャストしない — 呼び出しの各引数式は他の値式と全く
  同じ方法でチェックされる。
- **`@GoType` の引数・戻り値型は、その関数の本体がメソッドを一度も呼ばなくても、
  対応するバインディングの Go import を登録する。** ローカル変数は実際にバインディング
  呼び出しを書いたときだけ import が登録されるのと異なり、シグネチャにしか
  現れない型はそれ以外の方法では絶対に登録されないため。
- **ブロック本体内の `return expr;` / 素の `return;`。** 素の `return;`（void）と
  値を伴う `return`（non-void）のどちらが必要か、その値の型が宣言した戻り値型と
  一致するかは Dart 自身のアナライザに任せる — 他の箇所でも使っている「Dart 自身の
  型チェックを信頼する」という前提と同じ（例えば `docs/mapping.ja.md` は
  `int += double` が無効であることを改めて検証しない。Dart が既に拒否するため）。
- **式本体（`=> expr;`）** は non-void 関数（`return expr` になる）と `void` 関数の
  両方で使える（`void f() => print(s);` は Dart で普通の書き方）。Go は宣言された
  戻り値がない関数で `return <値>` を書けないので、`void` 関数の場合は `expr` を
  単独の文として出力し、`ExpressionStatement` と同じ方法でチェックする（そのため
  文として出力できる式だけを受け付け、任意の値式は受け付けない）。
- **このファイル内で宣言された関数の呼び出し**（`external` バインディングではない）は
  同じ名前の素の Go 呼び出しに対応する — 文として（バインディング呼び出しと同様、
  non-void の戻り値は捨てられる）、または値の式として。
- クロージャ、関数値、関数型の引数は対象外 — `FunctionDeclaration` だけを関数として
  認識する。関数を値として使おうとするもの（変数に代入する、引数として渡す）は、
  素の関数参照を値として扱うコードパスがどこにもないため、未対応の式として拒否される。

## 注釈バインディング（決定・実装済み）

`@GoName` 宣言（[`writing_bindings.ja.md`](./writing_bindings.ja.md) 参照）への呼び出しは
Go の呼び出しに 1:1 で対応し、トランスパイラがラッパーを足すことはない。

| Dart | Go |
| --- | --- |
| バインディングライブラリの `@GoImport('pkg/path', alias: 'p')` | `import p "pkg/path"`（そのライブラリのバインディングを使った場合のみ。`alias` なしなら `import "pkg/path"`） |
| `final d = newDisplay();`（`newDisplay` が `@GoName('wio.NewDisplay')`） | `d := wio.NewDisplay()`（`final`/`var` の違いはなし。`@GoType` は Go 側の型推論に任せる） |
| `beep(3);`（`beep` が `@GoName('rt.Beep')`） | `rt.Beep(3)` |
| `d.drawText(10, 20, 'hi');`（`drawText` が `@GoName('DrawText')`） | `d.DrawText(10, 20, "hi")` |
| `newDisplay().clear();`（呼び出し結果へのメソッドチェーン。#30 参照） | `wio.NewDisplay().Clear()` — レシーバをそのまま出力する。チェーンの深さは何段でも良い |
| `final n = sensor.read();` / `var ok = isReady();`（`int` / `double` / `bool` / `String` / `@GoType` の戻り値） | `n := sensor.Read()` / `ok := rt.IsReady()`（型は Go の推論に任せる。void 以外の戻り値を文として使った場合は捨てられる） |
| `red` / `Button.a`（getter が `@GoName('rt.Red')` / `@GoName('rt.ButtonA')`） | `rt.Red` / `rt.ButtonA` — 呼び出しなしの識別子 |
| 引数: `int` / `double` / `bool` / `String` のリテラル、ローカル変数、バインディング呼び出し、Go 定数の参照 | そのまま出力：型なし定数 / 識別子 / 呼び出し / 識別子。キャストは出さないので、Go 側の引数型は `int` / `float64` / `bool` / `string` か `@GoType` そのものにする |

生成する `go.mod`：Dart パッケージに `go/go.mod` を同梱しているバインディングごとに
`require <module> v0.0.0` と `replace <module> => <ローカル絶対パス>` を出力し、
続けて `go mod tidy` を実行する。それ以外は `go mod tidy` に任せる。

## 数値の意味論（2026-09-22 決定。`int` と `double` は実装済み）

- **`int` → Go の `int`**（プラットフォーム幅。SAMD51 などの 32bit MCU では 32bit で、32bit で桁あふれする）。
  理由：Dart 自身が Web（dart2js のビット演算は 32bit）でプラットフォーム依存の整数意味論を
  許容している前例があること、バインディングが境界ごとの変換なしに Go の慣用的な `int` を
  使えること、Cortex-M では 64bit 演算がソフトウェア実装になること。dart2js 利用者が知っている
  のと同じ注意書きを README に載せる。
- **`double` → `float64`**。サイズより正しさ。Dart に 32bit double の前例はなく、単精度 FPU 上で
  ソフト実装の double が遅いことより、精度が無言で落ちることの方が悪い。
- 整数リテラルは Go の型なし定数のまま（`x := 0`）。
- `~/` → Go の `/`（どちらも 0 方向への切り捨て）。`%` は異なる（Dart `-5 % 3 == 1`、Go は `-2`）
  ので下記ランタイムヘルパを経由する。
- `int`/`double` の算術（`+`/`-`/`*`、単項 `-`、複合代入 `+=`/`-=`/`*=`）は、両辺が一致する型
  （`int` 同士か `double` 同士、暗黙変換なし）で実装済み。`~/`/`%`/`~/=`/`%=` は `int` のみ、
  `/`/`/=` は `double` のみ（Dart の `/` は常に `double` を返すため）。上の v0.1 の表を参照。
- `int` ⇄ `double` 変換（`.toDouble()`/`.toInt()`/`.round()`）は実装済み。それぞれが橋渡しする
  方向にのみ限定する（`.toDouble()` は `int` に、`.toInt()`/`.round()` は `double` に）ことで、
  生成する Go のキャストが意味のないもの（恒等変換）にならないようにしている。

## `List<int>`（2026-09-22 決定、実装済み）

`List<int>` は Go の `[]byte` に対応する（`[]int` ではない）。この機能が存在する理由である
SD カード・I2C/UART・Wi-Fi/HTTP のバインディングはすべて `[]byte`（`io.Reader`/`io.Writer`、
`strconv`、ネットワークバッファ）でやり取りするし、Dart 自身も `List<int>` をバイトバッファの
型として使う（`Uint8List` は `List<int>` を継承する）。これは v0.2 で決めた汎用の
`List<T>` → `[]T` より狭いスコープで、`int` 以外の要素型（`List<double>`、`List<String>` など）
は v0.2 まで対象外のまま。

Dart 側の要素型は `int` だが、Go の `[]byte` の要素型は `byte`（`uint8`）なので、
読み書きのたびにこの境界を明示的なキャストで越える — これは `.toDouble()`/`.toInt()`/
`.round()` で既に使っている「意図的な変換」と同じ種類のもので、「キャストなし」原則への
違反ではない：

| Dart | Go |
| --- | --- |
| `<int>[1, 2, 3]`（または推論された `[1, 2, 3]`） | `[]byte{byte(1), byte(2), byte(3)}` |
| `data[i]`（読み取り） | `int(data[i])` |
| `data[i] = v;`（書き込み。プレーンな `=` のみ） | `data[i] = byte(v)` |
| `data.add(v);` | `data = append(data, byte(v))` — Dart の `List.add` はその場で変更し `void` を返すが、Go の `append` は新しいスライスを返すので再代入が必要 |
| `data.length` | `len(data)` |
| `String.fromCharCodes(data)` | `string(data)` — 名前付きコンストラクタ（`Duration(...)` と同じ `InstanceCreationExpression`）であり、static メソッド呼び出しではない |
| `s.codeUnits` | `[]byte(s)` |

リストの等価比較（`a == b`）は未対応：Go のスライスは（`nil` との比較を除いて）
`==` で比較できない（コンパイルエラーになる）ため、既存の「両辺が同じ型でなければ
ならない」比較ルールが `List<int>` を比較可能な型として挙げていないことで、自然に拒否される。

## `String` 操作（2026-09-22 決定、実装済み）

`.length` と `.substring` は Go 自身の `len(s)` / `s[start:end]` と全く同じ**バイト単位**の
インデックスで動作する — Dart の UTF-16 コード単位インデックスとは異なる。これは、この文書に
以前あった `.length` を `utf8.RuneCountInString` にするという未実装のプレースホルダに代わる
決定：それも Dart の意味論を独自に近似したもの（UTF-16 コード単位ではなく Unicode コード
ポイント — astral 文字ではやはりずれるが、ずれ方が違うだけ）に過ぎず、しかも `.substring` は
Go の `string` をスライスするのにバイトかルーンのインデックスが必要で、コード単位インデックス
では使えない。単純なバイト長／バイトスライスの方がシンプルで、自分自身と整合する
（`s.substring(0, s.length)` は常に全体を返す）し、圧倒的に多い ASCII のケース（設定キー、
プロトコルヘッダ、数値の文字列化）では正確。Dart の結果とずれるのは非 ASCII テキストのときだけで、
ここに挙げた他の選択肢もすべて抱える BMP／astral のクラスの制約と同じもの。

| Dart | Go |
| --- | --- |
| `a.length`（`a`: `String`） | `len(a)` |
| `a + b`（`a`、`b`: `String`） | `a + b` — Go 自身の `+` と同じ記号・同じ意味論 |
| `a.substring(start)` / `a.substring(start, end)` | `a[start:]` / `a[start:end]` |
| `a.codeUnits` | `[]byte(a)`（上の「List<int>」を参照） |

## switch 文（2026-09-22 決定、実装済み）

`switch` は Go 自身の `switch` に対応する。Dart 3 と Go はどちらもデフォルトで
fallthrough しないので、case を終わらせるための `break` は生成側で不要（v0.1 では
`switch` の `case` 内の裸の `break;` を特別扱いしない — 他の場所と同じ「while/for
ループの内側でのみ有効」というチェックをそのまま通す。現時点の用途では不要なため）。

定数値の `case` のみ、かつ `int`/`String`/`bool`/ユーザー定義 `enum` の switch 式に
限定する（`@GoType` バインディング enum の `switch` は対象外。下の「enum」参照）—
Go の `switch` にはパターンマッチがないため、定数以外の Dart 3 パターン
（`case var x:`、デストラクチャリング、オブジェクトパターン）はチェッカーが拒否する。
`case ... when ...` ガードやラベル付き case も同様に拒否する。

| Dart | Go |
| --- | --- |
| `switch (x) { case 0: ...; case 1: ...; default: ...; }` | `switch x { case 0: ...; case 1: ...; default: ...; }` — そのまま |
| `case a: case b: <body>`（連続する空の case） | `case a, b: <body>` — Dart の case グルーピング構文は文ではないので、隣接する空の case はカンマ区切りの値リストを持つ 1 つの Go `case` にまとめる |
| `case a: /* 何もせず default に落ちる */ default: <body>` | `default: <body>`（`a` の case は削除され、まとめられない）— Go の `default` には値リストがないが、他のどの `case` にも該当しない値は元々すべて `default` にマッチするので、空の case が `default` に落ちるのと結果的に同じになる |
| `case 'x':` / `case true:` / `case Mode.on:` | `case "x":` / `case true:` / `case ModeOn:` — case の値は switch 式と同じ型のリテラル（enum の switch 式なら同じ enum の値）でなければならず、暗黙の変換はしない |

v0.1 のスコープ外：`case ... when ...` ガード、定数以外／デストラクチャリングの
パターン、`switch` 内での `for`/`for-in` ラベルターゲット。

## カスケード（2026-09-22 決定、実装済み）

`a..b()..c()` は単一の Go 式にはならない — Go にはレシーバを繰り返さずに1つの値へ
一連の呼び出しを行う構文がないため — 一時変数と文の列に変換する。HANDOFF §4.4 に
ある `Pin.led..configure(...)` の例の通り。`@GoType` のバインディング値に限定し、
各カスケードセクションは必ず素の `..method(args)` バインディング呼び出しでなければ
ならない（v0.1 には自前のクラス・フィールドがなく、カスケードした getter/setter/
添字セクションには対応する意味がないため）。

| Dart | Go |
| --- | --- |
| `newDisplay()..clear()..drawText(40, 120, 'Hi');`（文として） | `_t0 := wio.NewDisplay()` の後 `_t0.Clear()`、`_t0.DrawText(40, 120, "Hi")` — 合成の `_t0`/`_t1`/... レシーバ。生成ファイル全体で一意 |
| `final d = newDisplay()..clear();`（ローカル変数の初期化子として） | `d := wio.NewDisplay()` の後 `d.Clear()` — ローカル変数自身の名前をレシーバに再利用し、合成の一時変数は不要 |

## `enum`（2026-09-22 決定、実装済み）

2種類あり、どちらも素の `enum` 構文で宣言する — 型パラメータ、`with`/`implements`
節、追加のフィールド・メソッド、値へのコンストラクタ引数はなし（v0.1 には
自前のクラスがなく、enum の値が呼び出すコンストラクタを持たないため）。

**ユーザー定義の enum**（`@GoType` なし）は `type E int` と `const ( ... iota )`
ブロック、値1つにつき1つの Go 識別子（`E` + 先頭を大文字にした値の名前。
例：`Mode.off` → `ModeOff`）、そして値自身でインデックスするパッケージレベルの
名前テーブルになる — Go は基底型が整数型であればどんな型でもインデックスに
使えるため（Go 標準ライブラリの `time.Month.String()` が自身の名前テーブルを
インデックスするのと同じ）、`e.name` にキャストは不要。`.index` はキャストが
必要（`int(e)`）：`e` の Go の型は `int` ではなく `E` であり、本プロジェクトの
「暗黙のキャストをしない」という前提（`.toInt()`/`.round()` と同様）に従う。
`==`/`!=` と `switch` は同じ enum の値同士でのみ対応し、Go 自身の `==`/`!=`/
`switch` にそのまま対応する（enum 型の `switch` の case 値は同じ enum の
定数でなければならない）。

| Dart | Go |
| --- | --- |
| `enum Mode { off, on }` | `type Mode int` + `const (ModeOff Mode = iota; ModeOn)` + `var modeNames = [...]string{"off", "on"}` |
| `Mode.on` | `ModeOn` |
| `m.name` | `modeNames[m]` |
| `m.index` | `int(m)` |
| `m == Mode.on` | `m == ModeOn` |
| `switch (m) { case Mode.off: ...; case Mode.on: ...; }` | `switch m { case ModeOff: ...; case ModeOn: ...; }` |

**バインディング enum**（enum に `@GoType`、各値に `@GoName`）は、`@GoType`
クラスの `external static` getter 定数（上の「注釈バインディング」の
`Button.a`）の enum 版：各 Dart 定数が既存の Go 識別子を表すと宣言するだけで、
生成器はこの enum 自体に対する Go 宣言を一切出力しない — 定数 getter と
全く同じ、素の `@GoName` 参照のみ。`.name`/`.index`/比較/`switch` は対象外：
値は不透明な Go 識別子であり、名前テーブルをインデックスしたり比較したり
するための Dart 側の int 表現を持たない。

| Dart | Go |
| --- | --- |
| `@GoType('tgm.Pin') enum Pin { @GoName('tgm.LED') led, @GoName('tgm.D0') d0 }` | この enum 自体には何も出力しない |
| `Pin.led` | `tgm.LED` |
| `high(Pin.led);` | `tgm.High(tgm.LED)` |

## クラス（継承なし）（2026-09-22 決定、実装済み）

v0.2、#32：`class Foo { ... }` は Go の `struct` + `func NewFoo(...) *Foo` +
ポインタレシーバのメソッドになる。インスタンスは常に `*Foo` —
Dart の参照意味論であり、インスタンス同士の `==`/`!=` は同一性比較
（Dart のデフォルトの挙動）で、これは Go 自身のポインタに対する `==` が
すでにやっていることと一致するため、それを再現するための追加コードは
不要。継承なし：`extends`/`implements`/`with` とすべてのクラス修飾子
（`abstract`/`base`/`final`/`interface`/`mixin`/`sealed`）は checker が
拒否する。ジェネリクス、`static` メンバー、getter/setter/演算子の
オーバーライド、nullable（`T?`）なフィールド／引数／戻り値の型も同様。

フィールドは対応済みの型のいずれかを宣言し、宣言時の初期化子を持っては
ならない — 値は必ずコンストラクタで設定する（そのため、値がどこで
決まるかを確認する場所がクラスにつき1箇所に定まる）。コンストラクタは
必ず1つ（継承がないのでフォールバック先となる暗黙のデフォルトコンス
トラクタが存在しない）：無名で、`const`/`factory`/`external` ではなく、
initializer list（`: field = expr, ...`）も使わない（Dart は宣言時
デフォルトを持たない non-nullable なフィールドをコンストラクタの本体が
実行される「前」に初期化することも要求するため、実質的にすべての
フィールドが `this.field` 引数を必要になる — 本体の文でできるのは、
すでに `this.field` で初期化済みのフィールドを「再代入」することだけで、
最初の代入はできない）。各パラメータは `this.field`（struct リテラルの
フィールドにそのまま対応）か、通常の位置引数（本体で使うためのもの）
のいずれか。名前付き／省略可能／デフォルト値付き引数はトップレベル
関数と同じ理由で非対応。コンストラクタ・メソッドの本体はトップレベル
関数と全く同じ方法でチェック・生成され、それに加えてフィールドの
アクセス・書き込みとインスタンスメソッド呼び出しに対応する。

フィールドアクセス — 暗黙の `this`（`value`）、明示的な `this.value`、
インスタンスを保持するローカル変数・フィールドに対する `c.value` —
はすべて同じ Go の形、`<レシーバ>.<フィールド>` にマップされる：
`this`／暗黙の `this` は、それを囲むメソッド自身のレシーバ変数名
（クラス名自身の先頭文字を小文字にしたもの。例：`Counter` → `c`）
になる。インスタンスメソッド呼び出しも同様：`c.inc()` / `this.inc()` /
（暗黙の `this` による）素の `inc()` はすべて `<レシーバ>.inc(...)` に
なる。これは `@GoType` バインディングのメソッド呼び出しと同じコード
パスを再利用しており、`@GoName` バインディングの代わりに素の
（`external` でない）`MethodElement` をキーにしているだけの違い。

| Dart | Go |
| --- | --- |
| `class Counter { int value; Counter(this.value); void inc() { value++; } }` | `type Counter struct { value int }` + `func NewCounter(value int) *Counter { return &Counter{value: value} }` + `func (c *Counter) inc() { c.value++ }` |
| `Counter(0)` | `NewCounter(0)` |
| `c.value` / `this.value`（メソッド内） / 素の `value`（メソッド内） | `c.value` / `c.value` / `c.value` — 常にレシーバで修飾される |
| `c.value = 5;` / `c.value += 1;` | `c.value = 5` / `c.value += 1` — ローカル変数と異なり、フィールドは素の `=` も受け付ける |
| `c.inc();` | `c.inc()` |
| `c1 == c2` | `c1 == c2` — ポインタの同一性比較。Dart のデフォルトの `==` と同じ |
| 本体を持つコンストラクタ（`this.field` 引数は初期化のみ。本体では再代入できる） | `<recv> := &Foo{...this.field による初期化...}` の後に本体の文、最後に `return <recv>` — `this.field` のみで本体を持たない単純なコンストラクタは、途中のローカル変数を省いて struct リテラルを直接返す |

v0.2 の対象外：継承・mixin・インターフェース、ジェネリクス、値を計算
するための initializer list（`: field = expr, ...` — 代わりに通常の
位置引数とコンストラクタ本体の文、またはメソッドを使う）、演算子の
オーバーロード。

## 型対応表（2026-09-22 決定。「実装済」は現時点で存在するもの）

| Dart | Go | 状態 |
| --- | --- | --- |
| `int` | `int` | 実装済（リテラル／ローカル変数／バインディング戻り値、`+`/`-`/`*`/`~/`/`%`、単項 `-`、複合代入、`.toDouble()`） |
| `double` | `float64`。`double d = 2;` → `d := 2.0`（Go が `int` と推論しないように） | 実装済（リテラル／ローカル変数／バインディング戻り値、`+`/`-`/`*`/`/`、単項 `-`、複合代入、`.toInt()`/`.round()`、文字列補間） |
| `bool` | `bool` | 実装済（リテラル／ローカル変数／バインディング戻り値、比較・論理演算子、`if`） |
| `String` | `string`。`.length` → `len(s)`（バイト長。理由は下の「List<int>」を参照）。`+` 連結、`.substring`。v0.1 では一般の添字アクセスなし | 実装済（リテラル／ローカル変数／バインディング戻り値、`+`、`.substring()`、`.length`、`.codeUnits`） |
| `Duration` | `time.Duration`。リテラルでない `Duration(milliseconds: n)` → `time.Duration(n) * time.Millisecond` | 実装済（リテラル） |
| `List<int>` | `[]byte` — 下の「List<int>」を参照 | 実装済 |
| `List<T>`（`T` が `int` 以外） | `[]T`。`add` → `append`、`length` → `len`、添字はそのまま、`List.filled` → `make` + ループ。growable/fixed は区別しない | 決定（v0.2） |
| `enum` | ユーザー定義 enum：`type E int` + `const ( ... iota )` + 名前テーブル、`.index`/`.name`/`==`/`switch` — 上の「enum」参照。`@GoType`/`@GoName` バインディング enum：定数の `@GoName` の値をそのまま | 実装済 |
| クラス（継承なし） | `struct` + `NewFoo(...)` + ポインタレシーバのメソッド。インスタンスは常に `*Foo`（Dart の参照意味論。`==` は同一性比較） — 上の「クラス（継承なし）」参照 | 実装済 |
| トップレベル関数 | `func`。位置引数のみ。名前付き／省略可能引数は checker が拒否 — 上の「トップレベル関数」を参照 | 実装済 |
| `if` / `else if` / `else` | そのまま対応。各分岐は必ずブロック（上の v0.1 の表を参照） | 実装済 |
| `while`（一般条件）/ `for`（宣言変数1つ、updater1つ）/ `break` / `continue` | そのまま対応。上の v0.1 の表を参照 | 実装済 |
| `for-in` | → `range` | 決定（v0.2） |
| `switch` | `switch`。定数の `int`/`String`/`bool`/ユーザー定義 `enum` case のみ、fallthrough なし、空の case はまとめる／削除する — 上の「switch 文」を参照 | 実装済 |
| `@GoType` バインディング値へのカスケード `a..b()..c()` | 一時変数（初期化子の場合はローカル変数自身の名前）+ 文の列 — 上の「カスケード」を参照 | 実装済 |
| バインディング呼び出し結果へのメソッドチェーン `a().b()` | そのまま対応 — 上の「注釈バインディング」を参照 | 実装済 |
| `@GoType` クラス | 注釈に書いた Go 型式をそのまま | 実装済 |
| 継承・mixin・ジェネリクス・`T?`・`throw`/例外・`async` | checker が拒否 | 決定（将来） |

## 共通 Go ランタイム（`dartrt`、2026-09-22 決定、実装済み）

Go の式一つで表せない意味論は、`packages/dart2tinygo/go/` の小さなボード非依存 Go モジュール
（module `github.com/o-ga09/dart2tinygo/packages/dart2tinygo/go`、import 名 `dartrt`）を経由する。
配布と接続はバインディングの `go/` と同じ規約（[`writing_bindings.ja.md`](./writing_bindings.ja.md)
参照）：ただし `dartrt` はどの `@GoImport` にも属さない（エントリポイント側のパッケージグラフが
トランスパイラ自身のパッケージに依存する理由はないため）ので、生成器は `package:dart2tinygo`
自身のパッケージ設定（`Isolate.resolvePackageUri`）から見つける。使ったときだけ import される。
中身：`Mod`（Dart の `%`。`%`・`%=` で使用、実装済み）、`FormatDouble`（Dart は `1.0` と出すが Go の
`strconv.FormatFloat` は `1`。実装済みで、文字列補間にも組み込み済み）。
これは言語意味論でありボード知識ではないので、本体にボード固有コードを入れない原則には反しない。

## 文字列補間（`int` / `double` / `bool` / `String` すべて実装済み）

- `fmt.Sprintf` は使わない。型に応じて `strconv` 等で連結する（TinyGo のバイナリ肥大化を防ぐため）。
- `int` → `strconv.Itoa`、`bool` → `strconv.FormatBool`、`String` → そのまま、`double` → `dartrt.FormatDouble`。補間式はローカル変数に限らず、対応している値の式（リテラル、ローカル変数、バインディング呼び出し、算術式、`.toDouble()`/`.toInt()`/`.round()`、Go 定数）なら何でもよい。`print(s)` も同様に任意の `String` 式を受け付ける。

## 生成する `go.mod`

- `go 1.25`（TinyGo 0.42 の下限）。`go mod tidy` が必要に応じて上げる。
- ツリー内 Go ランタイム（バインディング、`dartrt`）ごとに `require` + `replace` の組を 1 つ。
