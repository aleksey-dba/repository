SELECT 
	DB_NAME() database_name,
	OBJECT_SCHEMA_NAME(i.object_id) AS sch_name,
	OBJECT_NAME(i.object_id) AS tab_name,
	i.name AS index_name,
	DB_ID() database_id,
	i.object_id,
	i.index_id AS index_id,
	SUM(a.used_pages)/128  index_size_mb,
	p.partition_number, p.data_compression_desc data_compression,fg.name file_group
FROM sys.indexes AS i
	INNER JOIN sys.objects o ON o.object_id = i.object_id
	INNER JOIN sys.partitions AS p ON p.object_id = i.object_id AND p.index_id = i.index_id
	INNER JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
	INNER JOIN sys.filegroups fg ON fg.data_space_id = a.data_space_id
WHERE OBJECT_SCHEMA_NAME(i.object_id) <> 'sys' AND o.is_ms_shipped <> 1
GROUP BY OBJECT_SCHEMA_NAME(i.object_id), OBJECT_NAME(i.object_id), i.name, i.object_id, i.index_id, p.partition_number, p.data_compression_desc, fg.name

