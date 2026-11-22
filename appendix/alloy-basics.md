# 付録: Alloy の基本記法

本文で出てきた記法を中心に、Alloy 6 の基本をまとめたリファレンス。
例はできるだけダブルブッキングの題材で書き、`L38` のような行番号は
[`models/02-double-booking.als`](../models/02-double-booking.als) を指す。

---

## 0. まず押さえる世界観

Alloy の世界にあるのは**アトム**（それ以上分解できない「もの」）と、
アトムを並べた**タプルの集合（関係）**だけ。

```
Driver   = { D0, D1, D2 }                     -- アトムの集合（1列の関係）
assignee = { (J0, D0), (J1, D2) }             -- ペアの集合（2列の関係）
```

- 集合も、フィールドも、変数も、すべて関係
- 1要素の値 `D0` も「要素が1つの集合 `{D0}`」として扱われる
  → `d in j.offered` のように、要素と集合を同じ演算子で扱える

---

## 1. sig: アトムの集合を宣言する

```alloy
sig Driver {}                      -- L9: ドライバーの集合
```

| 書き方 | 意味 | 例 |
|---|---|---|
| `sig A {}` | A という集合 | `sig Driver {}` |
| `abstract sig A {}` | A 自身のアトムは持たず、子 sig だけで構成される | `abstract sig VehicleType {}` |
| `sig B extends A {}` | A の部分集合。兄弟の extends 同士は**互いに素** | `sig Truck extends Vehicle {}` |
| `sig B in A {}` | A の部分集合。他の部分集合と**重なってよい** | `sig Urgent in Job {}` |
| `one sig A {}` | アトムがちょうど1個 | `one sig Kei, Medium, Large extends VehicleType {}` |
| `lone sig` / `some sig` | 0〜1個 / 1個以上 | |
| `var sig A in B {}` | 時刻とともに中身が変わる部分集合 | `var sig Done in Job {}` |

`abstract sig` + `one sig ... extends` の組み合わせは、**列挙型**として使える。

```alloy
abstract sig Status {}
one sig Offered, Accepted, Cancelled extends Status {}
-- TypeScript の "offered" | "accepted" | "cancelled" に相当
```

---

## 2. フィールドと多重度

```alloy
sig Job {
  offered: set Driver,       -- L12
  var assignee: set Driver   -- L13
}
```

フィールドは「sig のアトム → 値」の関係を宣言する。
`offered` の正体は `Job -> Driver` の関係（ペアの集合）。

| 多重度 | 個数 | TypeScript で言うと |
|---|---|---|
| `one T` | ちょうど1 | `T` |
| `lone T` | 0 か 1 | `T \| null` |
| `some T` | 1 以上 | `[T, ...T[]]`（空でない配列） |
| `set T` | 0 以上 | `Set<T>` |

**注意: 多重度を省略すると `one` になる。** `driver: Driver` は「必ず1人」の意味。

`var` を付けると、そのフィールドは時刻ごとに値が変わる（Alloy 6）。付けなければ全時刻で同じ。

関係の中の多重度も書ける。

```alloy
sig Depot {
  schedule: Job -> lone Driver   -- 各 Job について、Driver は高々1人
}
```

---

## 3. 集合の演算

| 演算子 | 意味 | 例 |
|---|---|---|
| `+` | 和集合 | `j.offered + j.assignee` |
| `-` | 差集合 | `assignee - j -> Driver`（L32） |
| `&` | 共通部分 | `j.offered & j.assignee` |
| `in` | 部分集合（要素なら「属する」） | `d in j.offered`（L37） |
| `!in` / `not in` | 含まれない | `d !in j.assignee` |
| `=` / `!=` | 集合として等しい / 等しくない | `assignee' = assignee`（L22） |
| `#` | 要素数（整数を返す） | `#j.offered` |
| `none` | 空集合 | |
| `univ` | 全アトム | |

---

## 4. 関係の演算

### `->`（直積）: ペアを作る

```alloy
j -> d              -- { (j, d) } という1行の表
j -> Driver         -- j と全ドライバーのペア { (j, D0), (j, D1), (j, D2) }
```

L32 の `assignee - j -> Driver` は「表から j の行を全部消す」。

### `.`（ドット結合）: 関係をたどる

左の集合の要素から、関係を1歩たどった先の集合を返す。

```
assignee = { (J0, D0), (J1, D2) }

J0.assignee = { D0 }       -- 左から右へたどる（L38: j.assignee）
assignee.D2 = { J1 }       -- 右から左へたどる（D2 が担当している案件）
J2.assignee = { }          -- 行がなければ空集合
```

たどった先が空でもエラーにならず、**空集合が返る**。これは便利だが、落とし穴にもなる（8章）。

### `[]`（箱結合）: ドット結合の別の書き方

```alloy
assignee[j]   -- j.assignee と同じ
```

### その他の関係演算

| 演算子 | 意味 | 例 |
|---|---|---|
| `~r` | 転置（左右を入れ替え） | `~assignee` は Driver → Job |
| `^r` | 推移閉包（1歩以上たどる） | `d.^next`（ある地点から到達できる全地点） |
| `*r` | 反射推移閉包（0歩以上） | |
| `s <: r` | 左側を s に制限 | `j <: assignee`（j の行だけ） |
| `r :> s` | 右側を s に制限 | |
| `r ++ s` | 上書き（s に左側がある行は s で置き換え） | L32 は `assignee ++ j -> d` とも書ける |

---

## 5. 論理式

### 論理演算子

| 記号 | 別表記 | 意味 |
|---|---|---|
| `and` | `&&` | かつ |
| `or` | `\|\|` | または |
| `not` | `!` | でない |
| `implies` | `=>` | ならば |
| `iff` | `<=>` | 同値 |
| `A implies B else C` | | A なら B、そうでなければ C |

**`{ }` の中に改行で並べた式は、すべて `and` でつながる。**

```alloy
pred acceptFirstWins[j: Job, d: Driver] {   -- L36〜L40
  d in j.offered                            -- かつ
  no j.assignee                             -- かつ
  assignee' = assignee + j -> d
}
```

行の順番に意味はない。上から実行される命令ではない。

### 集合の個数を述べる（多重度キーワード）

| 書き方 | 意味 | 例 |
|---|---|---|
| `no S` | S は空 | `no j.assignee`（L38） |
| `lone S` | S は0か1個 | `lone j.assignee`（L58） |
| `one S` | S はちょうど1個 | |
| `some S` | S は1個以上 | `some assignee`（L87） |

### 量化子

```alloy
all j: Job | lone j.assignee                  -- すべての j について（L58）
some d: Driver | d in j.offered               -- ある d が存在して
no j: Job | #j.assignee > 1                   -- そんな j は存在しない
all j: Job, d: Driver | ...                   -- 複数の変数（L63）
all disj d1, d2: Driver | ...                 -- d1 と d2 は異なるアトム
```

`|` の後ろが本体。`{ }` で囲んで複数行にもできる。

```alloy
all j: Job {
  lone j.assignee
  j.assignee in j.offered
}
```

### let: 名前を付ける

```alloy
let a = j.assignee | some a implies a in j.offered
```

---

## 6. 段落: pred / fun / fact / assert

| 宣言 | 役割 | FP での感覚 |
|---|---|---|
| `pred P[x: A] { 論理式 }` | 名前付きの論理式。呼ぶまで効かない | `A → Bool` |
| `fun f[x: A]: B { 式 }` | 名前付きの式（集合や関係を返す） | `A → B` |
| `fact { 論理式 }` | **常に成り立つ前提**。世界そのものを制限する | 型で強制される性質 |
| `assert A { 論理式 }` | 成り立つはずの性質（検査の対象） | テストの期待値・定理 |

呼び出しは角括弧。

```alloy
acceptFirstWins[j, d]   -- pred の呼び出し
```

fact は強力だが危険。fact で書いた条件は**検査の対象から外れる**（最初から成り立つ前提になる）。
本文のモデルで、ダブルブッキングの条件を fact にせず assert にしているのはそのため。

---

## 7. 実行コマンド: run と check

```alloy
run 名前 { 論理式 } for スコープ      -- 論理式を満たす「例」を探す
check アサーション名 for スコープ     -- アサーションの「反例」を探す
```

| コマンド | 見つかったら | 見つからなかったら |
|---|---|---|
| `run` | 例が存在する（図で見られる） | その範囲では**例がない**（矛盾しているかも） |
| `check` | **反例**がある（図で見られる） | その範囲では反例がない（証明ではない） |

### スコープ（世界の大きさ）

| 書き方 | 意味 |
|---|---|
| `for 3` | 各 sig のアトムは最大3個 |
| `for 3 but 2 Driver` | Driver だけ最大2個、他は3個 |
| `for 3 but exactly 2 Driver` | Driver はちょうど2個 |
| `for 3 but 10 steps` | トレースの長さは最大10（Alloy 6） |
| `for 3 but 5 Int` | 整数のビット幅を5（-16〜15）にする |

L79 の `for 3 but 1 Driver, 10 steps` は「ドライバー1人、他は3個、10ステップまで」。

---

## 8. 時間（Alloy 6）

### 状態と次の状態

| 書き方 | 意味 |
|---|---|
| `assignee` | 今の状態の値 |
| `assignee'` | 次の状態の値 |

操作は「今の状態と次の状態の関係」として pred で書く。

- `'` なしの条件 → 事前条件（L37, L38）
- `'` ありの条件 → 事後条件（L39）

### 時相演算子

時相演算子が付いていない式は、**トレースの最初の時刻**について述べている。

| 演算子 | 意味 | 例 |
|---|---|---|
| `always F` | 今以降ずっと F | `always OneAssignee`（L71） |
| `eventually F` | 今以降いつか F | `eventually some assignee`（L87） |
| `after F` | 次の時刻で F | `after (d in j.assignee)`（L63） |
| `F until G` | G になるまで F が続く（G はいつか必ず起きる） | |
| `historically F` | 過去ずっと F | |
| `once F` | 過去のどこかで F | |
| `before F` | 1つ前の時刻で F | |

L44 の `always (stutter or some j, d | acceptNaive[j, d])` は
「**どの時刻でも**、何も変わらないか、どれかの承諾が起きる」という意味になる。

Alloy 6 のトレースは無限に続く（最後はループする）ものとして扱われる。`steps` はそのループを含めた長さの上限。

---

## 9. よくある落とし穴

| 落とし穴 | 何が起きるか | 対策 |
|---|---|---|
| 多重度の省略 | `f: T` は `one T` になり、「空」が許されない | 意図を明示して `lone` / `set` を書く |
| 空集合への結合 | `j.assignee.vehicle` は担当なしだと空集合。`=` だと偽、`in` だと真になる | 担当なしのときにどうなるべきかを先に決める |
| フレーム条件の書き忘れ | 操作で触れていない `var` は**勝手に変わってよい**ことになる | すべての `var` について次の値を書く（変わらないなら `x' = x`） |
| 検査の空振り | 事前条件が矛盾していると操作が起きず、check が「反例なし」になる | check の前に run で動く例を確かめる（L87） |
| fact の書きすぎ | 守りたい性質を fact にすると、それは検査されない | 守りたい性質は assert にする |
| 整数のあふれ | 既定のビット幅は4（-8〜7）。あふれると値が巡回する | `for 3 but 5 Int` などで広げる |
| スコープが小さすぎる | 反例に必要な数のアトムが用意されない（L79） | 「反例を作るには最低何個要るか」を考えてスコープを決める |

---

## 10. コメントとモジュール

```alloy
-- 1行コメント
// これも1行コメント
/* 複数行
   コメント */

module double_booking                 -- L7: ファイルのモジュール名
open util/ordering[Time]              -- 標準ライブラリの読み込み（本文ではまだ使っていない）
```
