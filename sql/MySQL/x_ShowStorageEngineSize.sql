DROP PROCEDURE IF EXISTS `x_ShowStorageEngineSize`;

DELIMITER $$
CREATE PROCEDURE `x_ShowStorageEngineSize` ()
BEGIN
  SELECT
    COALESCE(`ENGINE` , '') AS `Engine`
	,
    COUNT(*) AS `Tables`
	,
    `table_schema` AS `Schema`
	,
    SUM(`table_rows`) AS `Rows`
	,
    ROUND(SUM(`data_length`)/1024/1024/1024 , 2) AS `Data [GB]`
	,
    ROUND(SUM(`index_length`)/1024/1024/1024 , 2) AS `Index [GB]`
	,
    ROUND(SUM(`data_length` + `index_length`)/1024/1024/1024 , 2) AS `Total [GB]`
  FROM `information_schema`.`tables`
  GROUP BY `ENGINE`
  HAVING SUM(`table_rows`) > 0
  ORDER BY SUM(`data_length` + `index_length`) DESC ;
END$$
DELIMITER ;
