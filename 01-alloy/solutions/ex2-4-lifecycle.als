-- 第1章 演習2-4 解答
--
-- 2-4a: 反例の典型例
--   ドライバー d が確定案件を1件抱えた状態で、案件 j1 と j2 を同時に打診される
--   （どちらの打診時点でも空きは1つあった）。d が j1 を承諾すると空きがなくなり、
--   j2 の打診が「空きのないドライバーへの打診」になって Inv の最後の行が破れる。
--   最後の行を消しても、続けて j2 を承諾すれば上限を超える。
--   → 現実で言えば「並行して打診された案件を両方承諾してダブルブッキング」。
--
-- 2-4b:
--   「打診時点で空きがあった」は offer の【事前条件】であって、
--   時間が経っても成り立ち続ける【不変条件】ではない（他の案件の承諾で崩れる）。
--   正しくは、Inv から最後の行を消し、accept の事前条件で空きを確認し直す。
--   「チェックした時点と使う時点がずれる」のは TOCTOU と呼ばれる典型的なバグ。
--
-- 2-4c: 案件1件の状態
--   | 状態        | offeredTo | driver | Done | Cancelled |
--   |-------------|-----------|--------|------|-----------|
--   | 募集中       | なし       | なし    |      |           |
--   | 打診中       | d         | なし    |      |           |
--   | 確定         | なし       | d      |      |           |
--   | 完了         | なし       | d      | ✓    |           |
--   | キャンセル    | なし       | なし    |      | ✓         |
--
--   → 第2章ではこれを直和型にする:
--       type Job =
--         | { status: "open" }
--         | { status: "offered";   driver: DriverId }
--         | { status: "assigned";  driver: DriverId }
--         | { status: "completed"; driver: DriverId }
--         | { status: "cancelled" }
--     Inv のうち lone / 排他 / Done ⇒ 担当あり / Cancelled ⇒ 担当なし は型で消える。
--     残る「車種の一致」と「ドライバーごとの上限（案件をまたぐ制約）」は型では書きにくい
--     → 第3章の property-based testing の対象になる。

module ex2_4_lifecycle_solution

abstract sig VehicleType {}
one sig Kei, Medium, Large extends VehicleType {}

sig Driver {
  vehicle: one VehicleType
}

sig Job {
  requires: one VehicleType,
  var offeredTo: set Driver,
  var driver: set Driver
}

var sig Done in Job {}
var sig Cancelled in Job {}

fun MaxJobs: Int { 2 }

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

pred Inv {
  all j: Job {
    lone j.offeredTo
    lone j.driver
    no j.offeredTo or no j.driver
    (j.offeredTo + j.driver).vehicle in j.requires
    j in Done implies some j.driver
    j in Cancelled implies no (j.offeredTo + j.driver)
  }
  no Done & Cancelled
  all d: Driver | #activeJobs[d] <= MaxJobs
  -- 2-4b: 「打診中のドライバーには空きがある」は不変条件ではないので削除
}

pred offer[j: Job, d: Driver] {
  isOpen[j]
  d.vehicle = j.requires
  hasCapacity[d]
  offeredTo' = offeredTo + j -> d
  driver' = driver
  Done' = Done
  Cancelled' = Cancelled
}

pred accept[j: Job] {
  some j.offeredTo
  -- 2-4b: 承諾の時点で空きを確認し直す
  hasCapacity[j.offeredTo]
  driver' = driver + j -> j.offeredTo
  offeredTo' = offeredTo - j -> Driver
  Done' = Done
  Cancelled' = Cancelled
}

pred decline[j: Job] {
  some j.offeredTo
  offeredTo' = offeredTo - j -> Driver
  driver' = driver
  Done' = Done
  Cancelled' = Cancelled
}

pred complete[j: Job] {
  some j.driver
  j !in Done
  Done' = Done + j
  offeredTo' = offeredTo
  driver' = driver
  Cancelled' = Cancelled
}

pred cancel[j: Job] {
  j !in Done + Cancelled
  Cancelled' = Cancelled + j
  offeredTo' = offeredTo - j -> Driver
  driver' = driver - j -> Driver
  Done' = Done
}

pred stutter {
  offeredTo' = offeredTo
  driver' = driver
  Done' = Done
  Cancelled' = Cancelled
}

pred Init {
  no offeredTo
  no driver
  no Done
  no Cancelled
}

pred Step {
  (some j: Job, d: Driver | offer[j, d])
  or (some j: Job | accept[j])
  or (some j: Job | decline[j])
  or (some j: Job | complete[j])
  or (some j: Job | cancel[j])
  or stutter
}

pred Traces {
  Init and always Step
}

run showTrace {
  Traces
  eventually some Done
} for 3 but 8 steps

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

assert DeclinePreservesInv {
  all j: Job | (Inv and decline[j]) implies after Inv
}
check DeclinePreservesInv for 4

assert CompletePreservesInv {
  all j: Job | (Inv and complete[j]) implies after Inv
}
check CompletePreservesInv for 4

assert CancelPreservesInv {
  all j: Job | (Inv and cancel[j]) implies after Inv
}
check CancelPreservesInv for 4
