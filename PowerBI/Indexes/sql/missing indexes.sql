SELECT
	CONVERT(DECIMAL(18, 2), migs.user_seeks * migs.avg_total_user_cost * (migs.avg_user_impact * 0.01)) index_advantage,
mig.index_handle,
migs.group_handle,
	migs.avg_system_impact,
	migs.avg_total_system_cost,
	migs.last_system_scan,
	migs.last_system_seek,
	migs.system_scans,
	migs.system_seeks,
	migs.avg_user_impact,
	migs.avg_total_user_cost,
	migs.last_user_scan,
	migs.last_user_seek,
	migs.user_scans,
	migs.user_seeks,
	migs.unique_compiles,
	mid.database_id,
	mid.object_id,
	mic.column_name,
	CASE mic.column_usage WHEN 'EQUALITY' THEN '0 EQUALITY' WHEN 'INEQUALITY' THEN '1 INEQUALITY' WHEN 'INCLUDE' THEN '2 INCLUDE' END column_usage,
	mic.column_id,
	mid.statement full_object_name
FROM sys.dm_db_missing_index_groups mig
	INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
	INNER JOIN sys.dm_db_missing_index_details mid ON mid.index_handle = mig.index_handle
	OUTER APPLY sys.dm_db_missing_index_columns(mig.index_handle) mic;