-- -------------------------------------------------------------------------- --
-- AliSQL inventory tests                                                     --
-- -------------------------------------------------------------------------- --

pathtest = string.match(test, "(.*/)")

if pathtest then
   dofile(pathtest .. "common.lua")
else
   require("common")
end

-- overwrite create_insert fucntion in common.lua
create_insert = function(table_id)
  local query

  print("Creating table 'sbtest" .. table_id .. "'...")
  query = [[
CREATE TABLE sbtest]] .. table_id .. [[ (
id INT UNSIGNED NOT NULL,
c BIGINT UNSIGNED NOT NULL,
PRIMARY KEY (id)
)ENGINE =  InnoDB]]
  db_query(query)
  db_query("INSERT INTO sbtest" .. table_id .."(id, c) values (1, 1)")

end

-- overwrite prepare fucntion in common.lua
prepare = function()
  set_vars()
  db_connect()
  for i = 1, oltp_tables_count do
    create_insert(i)
  end
end


function thread_init(thread_id)
  set_vars()
  oltp_inventory_mysql_type = oltp_inventory_mysql_type or 'oracle'

  if (((db_driver == "mysql") or (db_driver == "attachsql")) and mysql_table_engine == "myisam") then
      begin_query = "LOCK TABLES sbtest WRITE"
      commit_query = "UNLOCK TABLES"
   else
      begin_query = "BEGIN"
      commit_query = "COMMIT"
   end
end

function event(thread_id)
  local table_name

  table_name = "sbtest" .. sb_rand_uniform(1, oltp_tables_count)

  if not oltp_skip_trx then
    db_query(begin_query)
  end

  -- please enable rds_ic_reduce_hint_enable for AliSQL
  if (oltp_inventory_mysql_type == "alisql") then
    db_query("UPDATE COMMIT_ON_SUCCESS ROLLBACK_ON_FAIL QUEUE_ON_PK 1 TARGET_AFFECT_ROW 1 " .. table_name .. " SET c=c+1 WHERE id = 1")
  else
    db_query("UPDATE " .. table_name .. " SET c=c+1 WHERE id = 1")
  end

  if not oltp_skip_trx then
    -- AliSQL commit automatically on success
    if (oltp_inventory_mysql_type ~= "alisql") then
      db_query(commit_query)
    end
  end
end
