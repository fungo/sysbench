-- -------------------------------------------------------------------------- --
-- use sysbench to simulate iibench                                           --
-- -------------------------------------------------------------------------- --

pathtest = string.match(test, "(.*/)")

if pathtest then
   dofile(pathtest .. "common.lua")
else
   require("common")
end

base_db = "xiangluo"

function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
function lines_from(file)
  if not file_exists(file) then return {} end
  local cids = {}
  for line in io.lines(file) do
    cids[#cids + 1] = line
  end
  return cids
end

-- tests the functions above
local file = 'cid.txt'
local cids = lines_from(file)

-- overwrite prepare fucntion in common.lua
prepare = function()
  set_vars()
  db_connect()
--  for i = 1, oltp_tables_count do
--    create_insert(i)
--  end
  create_insert()
end

cleanup = function()
  local i

  for i = 1, 4 do
    print("Dropping table '" .. base_db .. i .. ".rds_logs' ...")
    db_query("DROP TABLE " .. base_db .. i .. ".rds_logs")
  end
end

function thread_init(thread_id)
  set_vars()
end

function event(thread_id)
  local i
  local j
  local idx
  local query

  idx = sb_rand_uniq(1, #cids)
  query = "select"
  --print("select rds_logs.* from rt_sql_logs join rds_logs on rds_logs.id = rt_sql_logs.id where rt_sql_logs.`query`='" .. query.. ";filter=cid,".. cids[idx] .. ";limit=10' limit 10;")
  db_query("select rds_logs.* from rt_sql_logs join rds_logs on rds_logs.id = rt_sql_logs.id where rt_sql_logs.`query`='" .. query.. ";filter=cid,".. cids[idx] .. ";limit=10' limit 10;")
end
