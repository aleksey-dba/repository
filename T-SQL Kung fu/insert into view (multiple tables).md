![](img/tsqlcungfu.png)

CREATE TABLE test (i INT)
GO
CREATE VIEW view_test AS SELECT i FROM dbo.test
GO
INSERT INTO view_test SELECT 1
GO
SELECT i FROM view_test
GO
DELETE FROM view_test

--переіменування старої таблиці
sp_rename N'inf.sql_statistic_logical_disk', 'tab_sql_statistic_logical_disk_2022','object'
GO

--створення нової
CREATE TABLE inf.tab_sql_statistic_logical_disk (
	sqls_id INT NOT NULL,
	cluster_id BIGINT NOT NULL,
	machine_id BIGINT NOT NULL,
	disk_id BIGINT NOT NULL,
	dt SMALLDATETIME NOT NULL,
	collection_date BIGINT NOT NULL,
	free_gb DECIMAL(11, 2) NOT NULL,
	total_gb DECIMAL(11, 2) NOT NULL
) ON scpart_inf_sql_statistic_logical_disk (dt);

CREATE UNIQUE CLUSTERED INDEX ci_sql_statistic_logical_disk	ON inf.tab_sql_statistic_logical_disk (collection_date, sqls_id,  disk_id, dt) ON scpart_inf_sql_statistic_logical_disk(dt);

CREATE NONCLUSTERED INDEX ix_sqls_id
	ON inf.sql_statistic_logical_disk (sqls_id ASC)
	INCLUDE (collection_date)
	WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = ON)
	ON scpart_inf_sql_statistic_logical_disk(dt);

CREATE NONCLUSTERED INDEX ix_collection_date	ON inf.tab_sql_statistic_logical_disk (collection_date ASC)	ON scpart_inf_sql_statistic_logical_disk(dt);
GO


--створення подання/В'ю (view)
--зі старим іменем таблиці
--inf.sql_statistic_logical_disk

CREATE VIEW inf.sql_statistic_logical_disk
AS
SELECT sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb FROM inf.tab_sql_statistic_logical_disk_2022
UNION
SELECT sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb FROM inf.tab_sql_statistic_logical_disk





--наступні запити не виконаються, а помилка буде не надто очевидна )
--Update or insert of view or function 'inf.sql_statistic_logical_disk' failed because it contains a derived or constant field.
/*
	INSERT inf.sql_statistic_logical_disk (sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb)
	VALUES (1,	1,	1,	1,	'2022-09-22 00:33:42',	0, 	1,	1)

	UPDATE inf.sql_statistic_logical_disk
	SET free_gb=2
	WHERE dt>='2020-02-26'
		AND disk_id=45 
		AND collection_date=637183069253209165
*/
--Більш зрозуміло, SQL відповість, на спробу видалення
--View 'inf.sql_statistic_logical_disk' is not updatable because the definition contains a UNION operator.
/*
	DELETE 
	FROM inf.sql_statistic_logical_disk 
	WHERE dt>='2020-02-26'
		AND disk_id=45 
		AND collection_date=637183069253209165
*/


CREATE OR ALTER TRIGGER inf.instead_ins_sql_statistic_logical_disk ON inf.sql_statistic_logical_disk
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE inf SET 
		inf.cluster_id=i.cluster_id,
		inf.machine_id = i.machine_id,
		inf.free_gb=i.free_gb,
		inf.total_gb=inf.total_gb
	FROM Inserted i 
		JOIN inf.tab_sql_statistic_logical_disk inf ON inf.sqls_id = i.sqls_id 
			AND inf.disk_id = i.disk_id 
			AND inf.collection_date = i.collection_date

	--SET NOCOUNT OFF;
	INSERT INTO inf.tab_sql_statistic_logical_disk (sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb)
	SELECT i.sqls_id,
				 i.cluster_id,
				 i.machine_id,
				 i.disk_id,
				 i.dt,
				 i.collection_date,
				 i.free_gb,
				 i.total_gb 
	FROM Inserted i 
	WHERE NOT EXISTS(
		SELECT * 
		FROM inf.sql_statistic_logical_disk 
		WHERE sqls_id = i.sqls_id 
			AND disk_id = i.disk_id 
			AND collection_date = i.collection_date 
	);
END
GO


INSERT inf.sql_statistic_logical_disk (sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb)
VALUES (1,	1,	1,	1,	'2022-09-22 00:33:42',	0, 	1,	1)

UPDATE inf.sql_statistic_logical_disk
SET free_gb=2
WHERE dt>='2020-02-26'
	AND disk_id=45 
	AND collection_date=637183069253209165

go


CREATE OR ALTER TRIGGER inf.instead_del_sql_statistic_logical_disk ON inf.sql_statistic_logical_disk
INSTEAD OF DELETE
AS
BEGIN
	SET NOCOUNT ON;
	DELETE inf
	FROM 	Deleted i 
		JOIN inf.tab_sql_statistic_logical_disk inf ON inf.sqls_id = i.sqls_id 
			AND inf.disk_id = i.disk_id 
			AND inf.collection_date = i.collection_date

END
SELECT  * FROM inf.sql_statistic_logical_disk WHERE sqls_id = 1 AND disk_id=1 AND collection_date=0 
GO
DELETE FROM inf.sql_statistic_logical_disk WHERE sqls_id = 1 AND disk_id=1 AND collection_date=0 
GO
SELECT  * FROM inf.sql_statistic_logical_disk WHERE sqls_id = 1 AND disk_id=1 AND collection_date=0 
