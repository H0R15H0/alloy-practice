-- 第1章 演習2-4: 打診 → 承諾 フローと案件のライフサイクル
--
-- 要件は ex2-matching.als の末尾を参照。
-- offer と accept は実装済み。残りの TODO を埋めて、すべての check を通すこと。

module ex2_4_lifecycle

abstract sig VehicleType {}
one sig Kei, Medium, Large extends VehicleType {}

sig Driver {
  vehicle: one VehicleType
}

sig Job {
  requires: one VehicleType,
  var offeredTo: set Driver,     -- 打診中のドライバー
  var driver: set Driver         -- 確定した担当ドライバー（完了後も残る）
}

-- 「完了した案件」「キャンセルされた案件」の集合。時刻とともに変化する。
var sig Done in Job {}
var sig Cancelled in Job {}

fun MaxJobs: Int { 2 }

-- ドライバー d が現在抱えている（完了していない）確定案件
fun activeJobs[d: Driver]: set Job {
  driver.d - Done
}

pred hasCapacity[d: Driver] {
  #activeJobs[d] < MaxJobs
}

pred isOpen[j: Job] {
  no j.offeredTo
  no j.driver
  j !in Cancelled
}

--------------------------------------------------------------------------------
-- 不変条件
--------------------------------------------------------------------------------
pred Inv {
  all j: Job {
    lone j.offeredTo
    lone j.driver
    -- 打診中と確定済みは同時に起きない
    no j.offeredTo or no j.driver
    -- 打診先・担当の車種は要求車種と一致する
    (j.offeredTo + j.driver).vehicle in j.requires
    -- 完了した案件には担当者がいる
    j in Done implies some j.driver
    -- キャンセルされた案件には打診先も担当者もいない
    j in Cancelled implies no (j.offeredTo + j.driver)
  }
  no Done & Cancelled
  all d: Driver | #activeJobs[d] <= MaxJobs
  -- 打診中のドライバーには空きがある
  all j: Job, d: j.offeredTo | hasCapacity[d]
}

--------------------------------------------------------------------------------
-- 操作
--------------------------------------------------------------------------------

-- 打診
pred offer[j: Job, d: Driver] {
  isOpen[j]
  d.vehicle = j.requires
  hasCapacity[d]
  offeredTo' = offeredTo + j -> d
  driver' = driver
  Done' = Done
  Cancelled' = Cancelled
}

-- 承諾
pred accept[j: Job] {
  some j.offeredTo
  -- 打診した時点で空きを確認しており、Inv でも保証されているので、ここでは確認しない
  driver' = driver + j -> j.offeredTo
  offeredTo' = offeredTo - j -> Driver
  Done' = Done
  Cancelled' = Cancelled
}

-- 辞退
pred decline[j: Job] {
  -- TODO
}

-- 配送完了
pred complete[j: Job] {
  -- TODO
}

-- キャンセル（荷主による）
pred cancel[j: Job] {
  -- TODO
}

pred stutter {
  -- TODO: すべての var が変化しないこと
}

--------------------------------------------------------------------------------
-- トレース
--------------------------------------------------------------------------------
pred Init {
  -- TODO
}

pred Step {
  -- TODO: すべての操作のどれか1つ、または stutter
}

pred Traces {
  Init and always Step
}

run showTrace {
  Traces
  eventually some Done
} for 3 but 8 steps

--------------------------------------------------------------------------------
-- 検査
--------------------------------------------------------------------------------
assert InvAlways {
  Traces implies always Inv
}
check InvAlways for 3 but 10 steps

assert OfferPreservesInv {
  all j: Job, d: Driver | (Inv and offer[j, d]) implies after Inv
}
check OfferPreservesInv for 4

assert AcceptPreservesInv {
  all j: Job | (Inv and accept[j]) implies after Inv
}
check AcceptPreservesInv for 4

-- TODO: decline / complete / cancel についても同様の assert と check を書く

--------------------------------------------------------------------------------
-- 演習2-4a:
--   TODO を埋めたら AcceptPreservesInv を check せよ。反例が出るはずである。
--   反例を図で読み、「現実の業務で何が起きたか」を一文で説明せよ。
--
-- 演習2-4b:
--   accept の中のコメントの推論は、どこが間違っていたか？
--   Inv の最後の1行は本当に「不変条件」と呼べるものか？
--   ヒント: 事前条件と不変条件の違い
--   Inv と accept を直して、すべての check を通せ。
--
-- 演習2-4c:
--   案件1件がとりうる状態をすべて列挙し、それぞれの状態で
--   offeredTo / driver / Done / Cancelled がどうなっているかを表にせよ。
--------------------------------------------------------------------------------
