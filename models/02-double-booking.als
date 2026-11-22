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
