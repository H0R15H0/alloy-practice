-- 第1章 演習1: 関係と多重度
--
-- 題材: 荷主が出した「案件 (Job)」に「ドライバー (Driver)」を割り当てる。
-- 状態を「ある瞬間のスナップショット」として1つだけ考える。
-- Alloy の世界ではすべてが「関係（タプルの集合）」である。

module ex1_relations

-- 車種。abstract + one sig で「ちょうどこの3つだけ」の列挙型になる
abstract sig VehicleType {}
one sig Kei, Medium, Large extends VehicleType {}   -- 軽, 中型, 大型

sig Driver {
  vehicle: one VehicleType     -- 各ドライバーはちょうど1台の車両を持つ
}

sig Job {
  requires: one VehicleType,   -- 案件が要求する車種
  -- 各案件は高々1人(lone)のドライバーに割り当てられている
  --   lone = 0 or 1   (TypeScript の `Driver | null` に相当)
  --   one  = ちょうど1
  --   set  = 任意個
  driver: lone Driver
}

-- 何の制約もないインスタンスを眺める。
-- Execute → Instance で図を開き、「Next」で別の例を見てみよう。
run show {} for 3

--------------------------------------------------------------------------------
-- 式の読み方
--   j.driver          : 案件 j の担当ドライバー（0 or 1人）
--   driver.d          : ドライバー d が担当している案件の集合（関係を逆向きにたどる）
--   j.driver.vehicle  : 案件 j の担当ドライバーの車種（担当がいなければ空集合）
--   #S                : 集合 S の要素数
--   S in T            : S は T の部分集合（要素1つなら「属する」）
--------------------------------------------------------------------------------

-- 演習1-1:
--   上の `run show` を実行し、図の中の driver / vehicle / requires の矢印を確認せよ。
--   「大型案件に軽のドライバーが割り当てられている」ような、
--   現実にはおかしなインスタンスが出てくることを確認する。
--   → 制約を書かなければ、Alloy は何でもありの世界を見せてくる。

-- 演習1-2:
--   「2件以上担当しているドライバーがいる」インスタンスを探す run を書け。
--   ヒント: some d: Driver | ...
-- run someoneHasTwo { ... } for 3


-- 演習1-3:
--   ルール「1人のドライバーが同時に担当できるのは最大 2 件（混載）」を fact として追加せよ。
--   追加後、「3件担当しているドライバーがいる」run が No instance found になることを確かめよ。
fun MaxJobs: Int { 2 }

-- fact Capacity { ... }

-- run someoneHasThree { ... } for 4


-- 演習1-4:
--   ルール「担当ドライバーの車種は、案件の要求車種と一致する」を fact として追加せよ。
--   その後、次の assert を check して反例がないことを確かめよ。
--   ヒント: 担当がいない案件では j.driver.vehicle は空集合になる。
--          `=` で書くと担当なしの案件が許されなくなる。`in` との違いを考えよ。

-- fact VehicleMatch { ... }

assert NoKeiOnLargeJob {
  no j: Job | j.requires = Large and j.driver.vehicle = Kei
}
check NoKeiOnLargeJob for 4


-- 演習1-5:
--   次の assert は成り立つはずである。check して反例がないことを確認せよ。
--   その後、Job.driver の多重度を `lone` から `set` に変えて再度 check し、反例を図で見よ。
--   → 多重度は「型」のような役割を果たしていることを体感する。
assert NoDoubleAssign {
  all j: Job | lone j.driver
}
check NoDoubleAssign for 4


-- 演習1-6（発展）:
--   現実には「大型車は中型・軽の案件も運べる」。
--   車種 → 運べる車種 の関係 canCarry を定義し、1-4 の fact をそれを使って書き直せ。
--     fun canCarry: VehicleType -> VehicleType { ... }
--   ヒント: 関係は `Large -> Medium` のようなタプルの和集合 (+) で書ける。
--          担当がいない案件で式がどうなるか（空集合の扱い）に注意。
