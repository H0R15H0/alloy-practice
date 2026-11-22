# 第2回: 答えを仕様の言葉に直し、Alloy で確かめる

モデル: [`models/02-double-booking.als`](../models/02-double-booking.als)

## 第1回の問いへの答え

1. 2人が承諾したら → **先に承諾した方を優先し、後の方はエラー**
2. 型 → **「打診」状態と「承諾」状態の2つの型を作り、その遷移を関数で実装する**

## 答え1 を仕様の言葉に直す

「後の方はエラー」は、承諾という操作の**事前条件**になる。

> 承諾できるのは、その案件がまだ誰にも確定していないときだけ

Alloy では「満たさない場合はその操作が起きない」と書く（`no j.assignee`）。
実装では「満たさない場合はエラーを返す」になる。

## 素朴な実装と、その検査

事前条件を書かずに `job.driver = d` と上書きするだけの承諾（`acceptNaive`）を検査する。

| 検査 | 行 | 結果（予想） | 意味 |
|---|---|---|---|
| (1) 担当者は常に1人以下か | L71〜L72 | **反例なし** | 上書きなので、2人いる「状態」にはならない |
| (2) 確定した担当者は変わらないか | L75〜L76 | **反例あり** | A が承諾 → B が承諾 → A が黙って外される |
| (3) (2) をドライバー1人の世界で | L79 | 反例なし | 2人いないと起きない（「反例なし」≠ 正しい） |
| (4) 先勝ち版で (1) と (2) | L82〜L83 | 反例なし | 答え1 のルールで両方防げる |
| (5) 先勝ち版で承諾が実際に起こるか | L87 | 例あり | (4) が空振りでないことの確認（深掘り 6 を参照） |

素朴版の承諾は L30〜L33、先勝ち版は L36〜L40。性質は L57〜L59（状態）と L62〜L64（遷移）。

### ここが今回の一番大事なところ

ダブルブッキングには2つの顔がある。

| 種類 | 何を見るか | 例 |
|---|---|---|
| **状態の性質**（不変条件） | 1つの瞬間のスナップショット | 「担当者が2人いる」 |
| **遷移の性質** | 前の瞬間と次の瞬間の関係 | 「担当者が A から B に変わった」 |

不変条件だけ検査していると、(1) が通って安心してしまう。
でも現実には、A は「自分が担当だ」と思ったまま現地に向かう。
**何を確かめるか（性質の選び方）も仕様の一部**である。

## 答え2 との関係

```ts
type Offered  = { status: "offered";  offeredTo: DriverId[] }
type Accepted = { status: "accepted"; driver: DriverId }

const accept = (job: Offered, d: DriverId): Result<Accepted, Error> => ...
```

- `Accepted` は `driver` を1つしか持てない
  → 状態の性質（担当者は1人）は**型が保証**する。Alloy の (1) に相当
- `accept` の引数の型が `Offered` なので、確定済みの案件は渡せない
  → 事前条件（まだ確定していない）も**型が保証**する。Alloy の `no j.assignee` に相当

つまり答え2 の設計は、答え1 のルールを型で表したものになっている。

## 深掘り: `no j.assignee`（L38）は何をしているのか

行番号は [`models/02-double-booking.als`](../models/02-double-booking.als) のもの。全文はこのページ末尾の付録にある。

### 1. `j.assignee` は「関係をたどる」式

L13 の `var assignee: set Driver` は、Job ごとのフィールドに見えるが、Alloy の中では
**Job と Driver のペアの集合**（関係）である。

```
assignee = { (Job0, DriverA), (Job1, DriverB) }   -- ある瞬間の例
```

`j.assignee` は「この表のうち、左が j の行の右側を集めた集合」。

```
Job0.assignee = { DriverA }
Job2.assignee = { }          -- 担当なし
```

### 2. `no S` は「S が空集合」

| 書き方 | 意味 |
|---|---|
| `no S` | 0個 |
| `lone S` | 0個か1個（L58 で使っている） |
| `one S` | ちょうど1個 |
| `some S` | 1個以上（L87 で使っている） |

つまり L38 は「**案件 j にはまだ担当者がいない**」。

### 3. `'` が付いていないので「事前条件」

L36〜L40 の pred の中の各行は、上から順に実行される命令ではない。**全部が同時に成り立つ、という論理式（AND）**である。

| 行 | 式 | `'` | 何についての条件か |
|---|---|---|---|
| L37 | `d in j.offered` | なし | 今の状態 → 事前条件 |
| L38 | `no j.assignee` | なし | 今の状態 → 事前条件 |
| L39 | `assignee' = assignee + j -> d` | あり | 次の状態 → 事後条件 |

`'` の有無だけで、事前条件か事後条件かが決まる。行の順番は意味を持たない（L38 を L39 の下に書いても同じ）。

### 4. 「エラーにする」は Alloy ではどう表れるか

Alloy には「エラーを返す」という概念がない。L38 が偽になる状況では、pred 全体が偽になり、
**その承諾は「起こりえない遷移」になる**だけである。

L44 / L49 のトレースは「毎ステップ、stutter（何も変わらない）か、どれかの承諾が起きる」と書いている。
承諾が起こりえない状況では、次のステップは stutter か、別の承諾になる。

実装との対応:

| Alloy | 実装 |
|---|---|
| 事前条件が偽 → その遷移は起こらない | エラーを返し、**状態は変えない** |
| stutter（L21〜L23） | 状態が変わらない |

「エラーを返して状態を変えない」は、Alloy から見ると stutter と同じである。

### 5. L38 があるから、L39 は上書きではなく `+` でよい

素朴版の L32 は `assignee - j -> Driver + j -> d`（j の担当を全部消してから d を足す＝上書き）。
先勝ち版の L39 は `assignee + j -> d`（足すだけ）。

L38 で「j の担当は空」と言っているので、`- j -> Driver` は何も消さない。だから省ける。
もし L38 を消して L39 だけ残すと、2人目の承諾で `{A, B}` になり、
今度は**状態の性質**（L58 の `lone`）の方で反例が出る。

また L39 は `assignee` という関係**全体**の次の値を決めている。
「j 以外の案件の担当者は変わらない」ことも、この1行に含まれている（フレーム条件）。

### 6. 落とし穴: 事前条件を書き間違えると、検査が「空振り」する

L38 をうっかり `no j.assignee'`（`'` 付き）と書いたとする。

- L38: 次の状態で j の担当は空
- L39: 次の状態で j の担当に d がいる

これは同時には成り立たないので、**承諾が一度も起こらない**モデルになる。
すると L83 の check は「何も起きないから何も壊れない」という理由で**反例なし**になる。

これを見抜くために、L87 で「先勝ち版で、承諾が実際に起こるトレースがあるか」を `run` で確かめている。
**check の「反例なし」を信じる前に、run で「ちゃんと動く例がある」ことを確かめる**のが Alloy の定石。

### 7. TypeScript との対応

| Alloy | TypeScript |
|---|---|
| L38 `no j.assignee` | `accept` の引数の型が `Offered`（または `if (job.status !== "offered") return err(...)`） |
| L39 `assignee' = ...` | 戻り値 `Accepted` |
| L36〜L40 全体が1ステップ | `accept` の呼び出しが、読むことと書くことを一瞬で行う |

最後の行が次回の話につながる。L37〜L39 は**同じ1ステップの中で**今の状態を読み、次の状態を決めている。
つまりこのモデルは「確認してから書くまでの間に、他の人が割り込めない」と仮定している。

## 次回への問い: それでも本当に防げるか？

ドライバー A と B のアプリは、それぞれサーバーから案件を読み込んでいる。

```
A のアプリ: job を読む（status: offered）
B のアプリ: job を読む（status: offered）
A: accept(job, A)  → Accepted(A) を保存
B: accept(job, B)  → Accepted(B) を保存   ← 型検査は通る
```

B が持っている `job` は、もう古い `Offered` の値。
型は「その値が `Offered` である」ことは保証するが、「それが**今も**最新である」ことは保証しない。

Alloy のモデルでは、承諾は「読む」と「書く」が一瞬で起きる（原子的）と仮定していた。
次回は承諾を「読む」と「書く」の2ステップに分けて、この仮定を外すとどうなるかを確かめる。

## 付録: モデル全文（[`models/02-double-booking.als`](../models/02-double-booking.als)）

```alloy
-- 第2回: ダブルブッキングの最小モデル
--
-- 世界: 案件は、すでに何人かのドライバーに一斉打診されている。
--       打診されたドライバーは「承諾」できる。
-- 見たいこと: 承諾の仕方によって、ダブルブッキングが起きるかどうか。

module double_booking

sig Driver {}

sig Job {
  offered: set Driver,      -- 打診されたドライバー（変化しない）
  var assignee: set Driver  -- 確定した担当者（変化する）
                            -- あえて set にして「2人いる状態」も書けるようにしておく
}

pred Init {
  no assignee
}

pred stutter {
  assignee' = assignee
}

--------------------------------------------------------------------------------
-- 承諾の2つの書き方
--------------------------------------------------------------------------------

-- 素朴版: 担当者を上書きする（コードで job.driver = d と書くのと同じ）
pred acceptNaive[j: Job, d: Driver] {
  d in j.offered
  assignee' = assignee - j -> Driver + j -> d
}

-- 先勝ち版: まだ誰にも確定していないときだけ承諾できる（後の人はエラー）
pred acceptFirstWins[j: Job, d: Driver] {
  d in j.offered
  no j.assignee
  assignee' = assignee + j -> d
}

pred TracesNaive {
  Init
  always (stutter or some j: Job, d: Driver | acceptNaive[j, d])
}

pred TracesFirstWins {
  Init
  always (stutter or some j: Job, d: Driver | acceptFirstWins[j, d])
}

--------------------------------------------------------------------------------
-- 確かめたい性質
--------------------------------------------------------------------------------

-- 状態の性質（不変条件）: どの瞬間を見ても、担当者は高々1人
pred OneAssignee {
  all j: Job | lone j.assignee
}

-- 遷移の性質: 一度確定した担当者は、後から変わらない
pred NoOverwrite {
  all j: Job, d: Driver | d in j.assignee implies after (d in j.assignee)
}

--------------------------------------------------------------------------------
-- 検査
--------------------------------------------------------------------------------

-- (1) 素朴版 × 状態の性質
assert NaiveOneAssignee { TracesNaive implies always OneAssignee }
check NaiveOneAssignee for 3 but 10 steps

-- (2) 素朴版 × 遷移の性質
assert NaiveNoOverwrite { TracesNaive implies always NoOverwrite }
check NaiveNoOverwrite for 3 but 10 steps

-- (3) (2) と同じ検査を、ドライバー1人の世界で
check NaiveNoOverwrite for 3 but 1 Driver, 10 steps

-- (4) 先勝ち版 × 両方の性質
assert FirstWinsSafe { TracesFirstWins implies always (OneAssignee and NoOverwrite) }
check FirstWinsSafe for 3 but 10 steps

-- (5) 健全性チェック: 先勝ち版で、承諾が実際に起こりうるか
--     （これが No instance なら、(4) の「反例なし」は何も言っていない）
run FirstWinsCanAccept { TracesFirstWins and eventually some assignee } for 3 but 5 steps
```
