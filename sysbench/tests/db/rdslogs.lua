-- -------------------------------------------------------------------------- --
-- use sysbench to simulate iibench                                           --
-- -------------------------------------------------------------------------- --

pathtest = string.match(test, "(.*/)")

if pathtest then
   dofile(pathtest .. "common.lua")
else
   require("common")
end

-- overwrite create_insert fucntion in common.lua
--create_insert = function(table_id)
create_insert = function()
  local query

  print("Creating table 'rds_logs'...")
  query = [[
CREATE TABLE `rds_logs` (
  `global_id` bigint(20) NOT NULL,
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `ins_ip` char(32) NOT NULL,
  `ins_port` int(11) NOT NULL,
  `cid` int(11) NOT NULL,
  `tid` int(11) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `origin_time` bigint(20) DEFAULT NULL,
  `user_ip` char(32) DEFAULT NULL,
  `user` varchar(32) DEFAULT NULL,
  `db` varchar(32) DEFAULT NULL,
  `fail` varchar(32) DEFAULT NULL,
  `latency` bigint(20) DEFAULT NULL,
  `return_rows` bigint(20) DEFAULT NULL,
  `update_rows` bigint(20) DEFAULT NULL,
  `check_rows` bigint(20) DEFAULT NULL,
  `isbind` int(11) DEFAULT NULL,
  `s_hash` bigint(20) DEFAULT NULL,
  `log` text,
  `ins_name` varchar(32) NOT NULL DEFAULT 'ins',
  `db_type` varchar(32) NOT NULL DEFAULT 'db',
  `offset_id` bigint(20) DEFAULT NULL,
  `param_string` varchar(32) DEFAULT NULL,
  `extension` text,
  PRIMARY KEY (`id`,`cid`,`ts`,`db_type`,`global_id`),
  KEY `idx_cid` (`cid`,`db_type`,`ts`,`id`,`global_id`)
) /*! ENGINE = ]] .. mysql_table_engine .. " */"

  db_query(query)
end

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
  print("Dropping table 'rds_logs' ...")
  db_query("DROP TABLE rds_logs")
end

function thread_init(thread_id)
  local i

  set_vars()
  oltp_bulk_insert_batch_size = oltp_bulk_insert_batch_size or 20

  -- prepare strings ahead to avoid to many CPU consumes
  logs = {}
  extensions = {}
  for i = 1, oltp_bulk_insert_batch_size do
    logs[i] = sb_rand_str([[
###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########]])
--    extensions[i] = sb_rand_str([[
--###########-###########-###########-###########-###########-###########-###########-###########]])
    extensions[i] = sb_rand_str([[
###########-###########]])
  end
end

function event(thread_id)
  local i
  local j
  local table_name
  local global_id
  local ins_ip
  local ins_port
  local cid
  local tid
  local ts
  local origin_time
  local user_ip
  local user
  local db
  local fail
  local latency
  local return_rows
  local update_rows
  local check_rows
  local isbind
  local s_hash
  local ins_name
  local db_type
  local offset_id
  local param_string

  table_name = "rds_logs"
  db_bulk_insert_init("INSERT IGNORE INTO " .. table_name .. " VALUES")

  for i = 1, oltp_bulk_insert_batch_size do
    -- auto increment is on
    if (oltp_auto_inc) then
      j = 0
    else
      j = sb_rand_uniq(1, 10000000000)
    end
    --os.date("%Y-%m-%d %H:%M:%S")

    global_id = sb_rand_uniq(1, 10000);
    ins_ip = sb_rand_str("###.###.###.###")
    ins_port = sb_rand_uniq(1, 1000)
    cid = sb_rand_uniq(1, 1000)
    tid = sb_rand_uniq(1, 1000)
    ts = os.time()
    origin_time = ts
    user_ip = sb_rand_str("###.###.###.###")
    user = sb_rand_str("@@@@@@")
    db = sb_rand_str("@@@@@@")
    fail = "0"
    latency = sb_rand_uniq(1, 1000000)
    return_rows = sb_rand_uniq(1, 1000000)
    update_rows = sb_rand_uniq(1, 1000000)
    check_rows  = sb_rand_uniq(1, 1000000)
    isbind = 1
    s_hash = sb_rand_uniq(1, 1000000)
    ins_name = sb_rand_str("@@@@@@@@@@")
    db_type = "mysql"
    offset_id = sb_rand_uniq(1, 1000000)
    param_string = sb_rand_str("@@@@@@@")

    -- -- use the previously generated data values to avoid CPU consume to much
    db_bulk_insert_next(
    -----------------     id  ip   port cid tid ts o_time ip  user   db   fail
      string.format("(%d, %d, '%s', %d, %d, %d, %d, %d, '%s', '%s', '%s', '%s', %d, %d, %d, %d, %d, '%s', '%s', '%s', '%s', %d, '%s', '%s' )",
                    global_id, j, ins_ip, ins_port, cid, tid, ts, origin_time,
                    user_ip, user, db, fail, latency, return_rows, update_rows,
                    check_rows, isbind, s_hash, logs[i], ins_name, db_type,
                    offset_id, param_string, extensions[i]))

  end

  db_bulk_insert_done()
end
