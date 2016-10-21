pathtest = string.match(test, "(.*/)")

if pathtest then
   dofile(pathtest .. "common.lua")
else
   require("common")
end

function thread_init(thread_id)
  local i

  set_vars()
  oltp_bulk_insert_batch_size = oltp_bulk_insert_batch_size or 20

  -- prepare strings ahead to avoid to many CPU consumes
  c_vals = {}
  pad_vals = {}
  for i = 1, oltp_bulk_insert_batch_size do
    c_vals[i] = sb_rand_str([[
###########-###########-###########-###########-###########-###########-###########-###########-###########-###########]])
    pad_vals[i] = sb_rand_str([[
###########-###########-###########-###########-###########]])
  end
end

function event(thread_id)
  local i
  local j
  local table_name

  table_name = "sbtest".. sb_rand_uniform(1, oltp_tables_count)
  db_bulk_insert_init("INSERT INTO " .. table_name .. " VALUES")

  for i = 1, oltp_bulk_insert_batch_size do
    -- auto increment is on
    if (oltp_auto_inc) then
      j = 0
    else
      j = sb_rand_uniq(1, 10000000000)
    end
    -- use the previously generated c_vals and pad_vals to avoid CPU consume to much
    db_bulk_insert_next(string.format("(%d, %d, '%s', '%s')",  j, sb_rand(1, oltp_table_size) , c_vals[i], pad_vals[i]))
  end

  db_bulk_insert_done()
end
