# 形式手法 → 関数型プログラミング 演習

**1つの題材（物流: 荷主の案件とドライバーのマッチング）** を、4つの道具で書き直しながら進む演習です。

```
01-alloy       仕様を書き、反例を自動で探す          「何が正しいか」を決める
   ↓
02-typescript  仕様を代数的データ型 + 全域関数に落とす   「不正な状態を表現できなくする」
   ↓
03-pbt         型で書ききれない不変条件を検査する      Alloy の assert をそのままテストに
   ↓
04-lean        不変条件の保存を証明する             「検査」から「証明」へ
```

## 章ごとの対応表（最終的にこうなる）

| 概念 | Alloy | TypeScript | PBT (fast-check) | Lean |
|---|---|---|---|---|
| 状態 | `var` フィールド | discriminated union | `Arbitrary<State>` | `inductive` / `structure` |
| 不変条件 | `pred Inv` | 型 + smart constructor | `fc.property(...)` | `def Inv : State → Prop` |
| 操作 | `pred accept[...]` (事前/事後) | `accept: (s) => Result<State>` | コマンド列 | `def accept : State → Option State` |
| 保存性 | `check` (有限範囲で全探索) | 型検査 | ランダム検査 | `theorem` (全ケース証明) |

## 進め方

1. 各章の `README.md` を読む
2. `ex*.als` / `*.ts` / `*.lean` の `演習` を解く
3. 詰まったら `solutions/` を見る（まず自力で）
4. 章を終えたら次の章を一緒に作る

## 現在の進捗

- [x] 01-alloy
- [ ] 02-typescript
- [ ] 03-pbt
- [ ] 04-lean
