SELECT
	OBJECT_SCHEMA_NAME(p.object_id) sch_name, OBJECT_NAME(p.object_id) obj_name, p.index_id, p.partition_number, ix.name index_name, CONVERT(DECIMAL(10, 2), COUNT(*) / 128.0) buffer_size_mb, COUNT(*) buffer_count, p.rows row_count, p.data_compression_desc
FROM sys.allocation_units a WITH(NOLOCK)
	INNER JOIN sys.dm_os_buffer_descriptors b WITH(NOLOCK)ON a.allocation_unit_id = b.allocation_unit_id
	INNER JOIN sys.partitions p WITH(NOLOCK)ON a.container_id = p.hobt_id
	INNER JOIN sys.indexes ix ON ix.index_id = p.index_id
													 AND ix.object_id = p.object_id
WHERE b.database_id = DB_ID()
GROUP BY OBJECT_SCHEMA_NAME(p.object_id), OBJECT_NAME(p.object_id), p.index_id, p.partition_number, ix.name, p.rows, p.data_compression_desc 

