# 第1章: Alloy で仕様を書く

題材: **荷主が出した案件 (Job) に、ドライバー (Driver) をマッチングする**

## セットアップ

1. Alloy 6 の jar を入手する: https://github.com/AlloyTools/org.alloytools.alloy/releases
   （`org.alloytools.alloy.dist.jar`。`tools/` に置けば `.gitignore` 済み）
2. 起動: `java -jar tools/org.alloytools.alloy.dist.jar`（Java 17 以上が必要）
3. `File > Open` で `.als` を開き、ツールバーの `Execute` で `run` / `check` を実行する
   - `run`  : 条件を満たす**例**を探す → 見つかれば `Instance` を開いて図で見る
   - `check`: assert の**反例**を探す → 見つからなければ「その範囲では成り立つ」

## この章で身につけること

| 概念 | 意味 | FP での見え方（予告） |
|---|---|---|
| sig | 集合（要素の種類） | 型 |
| `abstract sig` + `one sig` | ちょうどこれだけの要素 | 列挙型 (`"kei" \| "medium" \| "large"`) |
| フィールドと多重度 (`lone`, `one`, `set`) | 関係とその制約 | `T \| null`, `T`, `T[]` |
| fact | 常に成り立つ前提 | 型で強制される性質 |
| pred | 名前付きの論理式（状態の性質・操作） | 型述語・関数 |
| assert / check | 成り立つはずの性質とその検査 | テスト・定理 |
| `x'` (次の状態) | 操作の事後条件 | 関数の戻り値 |

**有限範囲で全探索**するのが Alloy の特徴です。「小さな反例はたいてい存在する」（small scope hypothesis）という経験則に基づいています。証明ではありませんが、仕様のバグは驚くほどよく見つかります。

## 演習

### ex1-relations.als（静的モデル: 状態を1つだけ見る）
- 1-1 〜 1-5: 関係・多重度・fact・assert の基本、車種の適合
- 1-6（発展）: 「大型は小さい案件も運べる」を関係で書く

### ex2-matching.als（動的モデル: 状態が変化する）
- 2-1: 仕込まれたバグを `check` で見つける
- 2-2: 操作の事前条件を直す
- 2-3: 2種類の check（トレース検査と帰納的検査）の違いを理解する

### ex2-4-lifecycle.als（設計: 打診 → 承諾 フロー）
- 2-4a: 雛形を埋めると、ある操作に反例が出る。現実の業務で何が起きたかを読み解く
- 2-4b: 仕様のどこが間違っていたかを見つけて直す
- 2-4c: 案件1件の状態を列挙する（第2章の直和型の設計図になる）

解答は `solutions/` にあります。
