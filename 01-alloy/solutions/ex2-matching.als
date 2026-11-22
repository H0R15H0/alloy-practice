-- 第1章 演習2 解答（2-1 〜 2-3）
--
-- 2-1: assign に車種のチェックがないため、軽のドライバーが大型案件に割り当てられ、
--      `j.driver.vehicle in j.requires` が破れる。
--
-- 2-3:
--   - (B) Inv が Init で成り立ち、どの操作でも保存されるなら、
--     到達可能な全状態で成り立つ（時刻に関する帰納法）。よって (B) ⇒ (A)。
--   - 逆は成り立たない。到達不能な「変な状態」から操作すると Inv が破れる場合、
--     (A) は成り立つが (B) は反例が出る。その場合は Inv を強める
--     （帰納的不変条件を見つける）必要がある。

module ex2_matching_solution

abstract sig VehicleType {}
one sig Kei, Medium, Large extends VehicleType {}

sig Driver {
  vehicle: one VehicleType
}

sig Job {
  requires: one VehicleType,
  var driver: set Driver
}

fun MaxJobs: Int { 2 }

pred Inv {
  all j: Job {
    lone j.driver
    j.driver.vehicle in j.requires
  }
  all d: Driver | #driver.d <= MaxJobs
}

pred assign[j: Job, d: Driver] {
  no j.driver
  #driver.d < MaxJobs
  -- 2-2 の修正: 車種のチェック
  d.vehicle = j.requires
  driver' = driver + j -> d
}

pred complete[j: Job] {
  some j.driver
  driver' = driver - j -> Driver
}

pred stutter {
  driver' = driver
}

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

run showTrace {
  Traces
  eventually some driver
} for 3 but 5 steps

assert InvAlways {
  Traces implies always Inv
}
check InvAlways for 3 but 10 steps

assert AssignPreservesInv {
  all j: Job, d: Driver | (Inv and assign[j, d]) implies after Inv
}
check AssignPreservesInv for 4

assert CompletePreservesInv {
  all j: Job | (Inv and complete[j]) implies after Inv
}
check CompletePreservesInv for 4
