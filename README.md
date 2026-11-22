# 形式手法 → 関数型プログラミング 伴走ノート

**1つの題材（物流: 荷主の案件をドライバーにマッチングするときのダブルブッキング）** のモデルを育てながら、
形式手法から関数型プログラミング（代数的データ型）への流れの全体像をつかむための記録です。
問題集ではなく、回ごとに「考えたこと・育てたモデル・要点」を残していきます。

## 全体の流れ

```
Alloy  : 状態・不変条件・操作を決めて、仕様の穴を潰す
  ↓
TS     : 不変条件のうち、型に入るものを型に入れる（代数的データ型）
  ↓
PBT    : 型に入らなかった不変条件を、実装に対して検査する
  ↓
Lean   : それを証明する
```

## セッション

- [第1回: 形式手法は何をしているのか](sessions/01-overview.md)
- [第2回: 答えを仕様の言葉に直し、Alloy で確かめる](sessions/02-model.md)

## Alloy の動かし方

1. [Releases](https://github.com/AlloyTools/org.alloytools.alloy/releases) から `org.alloytools.alloy.dist.jar` を入手して `tools/` に置く
2. `java -jar tools/org.alloytools.alloy.dist.jar`（Java 17 以上）
3. `models/*.als` を開き、メニューの `Execute` から各 `check` を実行する
