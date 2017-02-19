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

  print("Creating table 'purchases_index'...")
  query = [[
CREATE TABLE purchases_index (
transactionid int NOT NULL AUTO_INCREMENT,
dateandtime datetime DEFAULT NULL,
cashregisterid int NOT NULL,
customerid int NOT NULL,
productid int(11) NOT NULL,
price float NOT NULL,
data varchar(4000) DEFAULT NULL,
PRIMARY KEY (transactionid),
KEY marketsegment (price, customerid),
KEY registersegment (cashregisterid, price, customerid),
KEY pdc (price, dateandtime, customerid)
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
  print("Dropping table 'purchases_index' ...")
  db_query("DROP TABLE purchases_index")
end

function thread_init(thread_id)
  local i

  set_vars()
  oltp_bulk_insert_batch_size = oltp_bulk_insert_batch_size or 20

  -- prepare strings ahead to avoid to many CPU consumes
  data = {}
  for i = 1, oltp_bulk_insert_batch_size do
    data[i] = sb_rand_str([[
###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########-###########]])
  end
end

function event(thread_id)
  local i
  local j
  local table_name
  local date_time
  local registerid
  local customerid
  local productid
  local price

  table_name = "purchases_index"
  db_bulk_insert_init("INSERT IGNORE INTO " .. table_name .. " VALUES")

  for i = 1, oltp_bulk_insert_batch_size do
    -- auto increment is on
    if (oltp_auto_inc) then
      j = 0
    else
      j = sb_rand_uniq(1, 10000000000)
    end
    --os.date("%Y-%m-%d %H:%M:%S")

    date_time = "2016-12-20 15:38:28"
    registerid = sb_rand_uniq(1, 10000000000)
    customerid = sb_rand_uniq(1, 10000000000)
    productid = sb_rand_uniq(1, 10000000000)
    price = sb_rand_uniq(1, 10000000000)

    -- use the previously generated data values to avoid CPU consume to much
    db_bulk_insert_next(string.format("(%d, '%s', %d, %d, %d, %f, '%s')",  j, date_time, registerid, customerid, productid, price, data[i]))
  end

  db_bulk_insert_done()
end
