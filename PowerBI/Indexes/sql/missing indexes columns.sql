
SELECT mid.index_handle, ROW_NUMBER() OVER (PARTITION BY mid.index_handle ORDER BY GETDATE()) rid, REPLACE(REPLACE(TRIM(ec.value),'[',''),']','') equality_column FROM
sys.dm_db_missing_index_details mid
CROSS APPLY STRING_SPLIT(mid.equality_columns,',') ec


SELECT mid.index_handle, ROW_NUMBER() OVER (PARTITION BY mid.index_handle ORDER BY GETDATE()) rid, REPLACE(REPLACE(TRIM(ic.value),'[',''),']','') inequality_column FROM
sys.dm_db_missing_index_details mid
CROSS APPLY STRING_SPLIT(mid.inequality_columns,',') ic

