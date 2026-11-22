-- 第1章 演習1 解答

module ex1_relations_solution

abstract sig VehicleType {}
one sig Kei, Medium, Large extends VehicleType {}

sig Driver {
  vehicle: one VehicleType
}

sig Job {
  requires: one VehicleType,
  driver: lone Driver
}

run show {} for 3

-- 演習1-2
run someoneHasTwo {
  some d: Driver | #driver.d >= 2
} for 3

-- 演習1-3
fun MaxJobs: Int { 2 }

fact Capacity {
  all d: Driver | #driver.d <= MaxJobs
}

-- No instance found になる
run someoneHasThree {
  some d: Driver | #driver.d >= 3
} for 4

-- 演習1-4
-- `j.driver.vehicle = j.requires` だと、担当なし（左辺が空集合）の案件が存在できなくなる。
-- `in` なら「空集合 ⊆ 何でも」なので担当なしも許される。
fact VehicleMatch {
  all j: Job | j.driver.vehicle in j.requires
}

assert NoKeiOnLargeJob {
  no j: Job | j.requires = Large and j.driver.vehicle = Kei
}
check NoKeiOnLargeJob for 4

-- 演習1-5
-- driver: lone Driver のままなら反例なし。
-- driver: set Driver に変えると、1件に2人が割り当てられた反例が出る。
assert NoDoubleAssign {
  all j: Job | lone j.driver
}
check NoDoubleAssign for 4

-- 演習1-6（発展）
-- 使う場合は上の VehicleMatch を消して、こちらを有効にする。
fun canCarry: VehicleType -> VehicleType {
    Large  -> (Large + Medium + Kei)
  + Medium -> (Medium + Kei)
  + Kei    -> Kei
}

-- `j.requires in j.driver.vehicle.canCarry` と書くと、担当なしの案件では
-- 右辺が空集合になり偽になってしまう。担当がいるときだけ要求する。
-- fact VehicleCanCarry {
--   all j: Job | some j.driver implies j.requires in j.driver.vehicle.canCarry
-- }
