-- 第1章 演習2: 状態の変化と不変条件
--
-- Alloy 6 では `var` を付けたフィールドは時刻とともに変化する。
--   driver   : 今の状態
--   driver'  : 次の状態
-- 操作は「今の状態と次の状態の関係（事前条件 + 事後条件）」として書く。

module ex2_matching

abstract sig VehicleType {}
one sig Kei, Medium, Large extends VehicleType {}

sig Driver {
  vehicle: one VehicleType       -- 変化しない
}

sig Job {
  requires: one VehicleType,     -- 変化しない
  -- あえて `set` にしている。
  -- 「1案件に高々1人」は多重度で強制せず、不変条件として明示し、
  -- 操作がそれを守るかどうかを検査したいから。
  var driver: set Driver
}

fun MaxJobs: Int { 2 }

--------------------------------------------------------------------------------
-- 不変条件
--------------------------------------------------------------------------------
pred Inv {
  all j: Job {
    -- 1案件の担当は高々1人
    lone j.driver
    -- 担当ドライバーの車種は要求車種と一致する
    j.driver.vehicle in j.requires
  }
  -- 1人が同時に担当できるのは最大 MaxJobs 件
  all d: Driver | #driver.d <= MaxJobs
}

--------------------------------------------------------------------------------
-- 操作
--------------------------------------------------------------------------------

-- マッチング（案件にドライバーを割り当てる）
pred assign[j: Job, d: Driver] {
  -- 事前条件
  no j.driver
  #driver.d < MaxJobs
  -- 事後条件
  driver' = driver + j -> d
}

-- 配送完了（ドライバーを解放する）
pred complete[j: Job] {
  -- 事前条件
  some j.driver
  -- 事後条件
  driver' = driver - j -> Driver
}

-- 何もしない（時間だけ進む）
pred stutter {
  driver' = driver
}

--------------------------------------------------------------------------------
-- トレース（システムの振る舞い全体）
--------------------------------------------------------------------------------
pred Init {
  no driver
}

pred Step {
  (some j: Job, d: Driver | assign[j, d])
  or (some j: Job | complete[j])
  or stutter
}

pred Traces {
  Init and always Step
}

-- 振る舞いの例を眺める。図の上部の矢印で時刻を進められる。
run showTrace {
  Traces
  eventually some driver
} for 3 but 5 steps

--------------------------------------------------------------------------------
-- 検査
--------------------------------------------------------------------------------

-- (A) トレース検査: 初期状態から到達できるどの状態でも Inv が成り立つか
assert InvAlways {
  Traces implies always Inv
}
check InvAlways for 3 but 10 steps

-- (B) 帰納的検査: Inv を満たす「任意の」状態から操作しても Inv が保たれるか
--     （初期状態から到達できるかどうかは問わない）
assert AssignPreservesInv {
  all j: Job, d: Driver | (Inv and assign[j, d]) implies after Inv
}
check AssignPreservesInv for 4

assert CompletePreservesInv {
  all j: Job | (Inv and complete[j]) implies after Inv
}
check CompletePreservesInv for 4

--------------------------------------------------------------------------------
-- 演習2-1:
--   check InvAlways を実行すると反例が見つかる。
--   反例のトレースを図で追い、どの時刻でどの不変条件が破れたか特定せよ。
--
-- 演習2-2:
--   assign の事前条件を直して、InvAlways と AssignPreservesInv の反例を消せ。
--
-- 演習2-3（考察）:
--   (A) と (B) の違いを考えよ。
--     - (B) が成り立てば (A) も成り立つのはなぜか？（ヒント: 帰納法）
--     - (A) は成り立つが (B) は成り立たない、ということはあり得るか？
--   → この「(B) 帰納的な保存性」こそが、第4章で Lean で証明する定理になる。
--
-- 演習2-4（設計）: 打診 → 承諾 フローと案件のライフサイクル
--   現実のマッチングでは、いきなり割り当てず、まずドライバーに「打診」する。
--   要件:
--     - 募集中の案件を、車種が合い、空きのあるドライバー1人に打診 (offer) できる
--     - 打診されたドライバーは承諾 (accept) するか辞退 (decline) する
--         承諾 → 割当確定 / 辞退 → 募集中に戻る
--     - 確定した案件は、ドライバーが配送完了 (complete) にする（完了後も担当者は記録に残す）
--     - 荷主は完了前ならいつでもキャンセル (cancel) できる
--     - 同時担当数の上限は、完了していない確定案件で数える
--   やること:
--     1. ex2-4-lifecycle.als の雛形を埋める
--     2. 全操作について保存性の check を通す
--     3. 案件1件がとりうる状態をすべて列挙し、それぞれの状態で
--        「どのフィールドに値があるか」を表にせよ
--        → これが第2章で TypeScript の直和型になる
--------------------------------------------------------------------------------
