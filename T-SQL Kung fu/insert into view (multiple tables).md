![T-SQL Kung fu](img/tsqlcungfu.png)

# Модифікація даних (INSERT, UPDATE, DELETE) через подання (VIEW)

Якщо на вашу думку, наступний запит не виконається, у вас точно не чорний пояс по T-SQL:
```sql
CREATE VIEW inf.sql_statistic_logical_disk
AS
SELECT sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb 
FROM inf.tab_sql_statistic_logical_disk_2022
UNION
SELECT sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb 
FROM inf.tab_sql_statistic_logical_disk

GO
INSERT inf.sql_statistic_logical_disk (sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb)
VALUES (1,	1,	1,	1,	'2022-09-22 00:33:42',	0, 	1,	1)
```

У не дуже далекоглядної Панди, трапилась біда. 
Дуже потрібна і "популярна" таблиця розпухла, і тепер валяться таймаути. Але сервіс повинен працювати 24/7, і ніхто за переривання роботи сервісу премію не дасть.

Саме час для паніки? 
Ще рано.

Гадаю для більшості, не стане новиною, що SQL Server дозволяє модифікувати дані `INSERT, UPDATE, DELETE` через подання (`view`):

```sql
CREATE TABLE test (i INT)
GO
CREATE VIEW view_test AS SELECT i FROM dbo.test
GO
INSERT INTO view_test SELECT 1
GO
SELECT i FROM view_test
GO
DELETE FROM view_test

```
І Панда це знав.
Однак, що якщо ваше подання виглядає трохи складніше?

Не гаючи часу на документацію, Панда перейшов до дії:

- переіменував стару таблицю

```sql 
sp_rename N'inf.sql_statistic_logical_disk', 'tab_sql_statistic_logical_disk_2022','object'
GO
```
- створив нову (але незважаючи на недоліки, Панда вчиться на помилках і розбиває таблицю по місяцям) `ON scpart_inf_sql_statistic_logical_disk (dt);`

```sql
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

CREATE NONCLUSTERED INDEX ix_collection_date ON inf.tab_sql_statistic_logical_disk (collection_date ASC)	ON scpart_inf_sql_statistic_logical_disk(dt);
GO
```

- створює подання (view) зі старим іменем таблиці
`inf.sql_statistic_logical_disk`

```sql
CREATE VIEW inf.sql_statistic_logical_disk
AS
SELECT sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb FROM inf.tab_sql_statistic_logical_disk_2022
UNION
SELECT sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb FROM inf.tab_sql_statistic_logical_disk
```

Але наступні запити не виконуються, а помилка буде не очевидна.

```sql
	INSERT inf.sql_statistic_logical_disk (sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb)
	VALUES (1,	1,	1,	1,	'2022-09-22 00:33:42',	0, 	1,	1)

	UPDATE inf.sql_statistic_logical_disk
	SET total=2
	WHERE dt>='2020-02-26'
		AND disk_id=45 
		AND collection_date=637183069253209165
```
> Update or insert of view or function 'inf.sql_statistic_logical_disk' failed because it contains a derived or constant field.

Більш зрозуміло, SQL відповість, на спробу видалення

```sql
	DELETE 
	FROM inf.sql_statistic_logical_disk 
	WHERE dt>='2020-02-26'
		AND disk_id=45 
		AND collection_date=637183069253209165
```

> View 'inf.sql_statistic_logical_disk' is not updatable because the definition contains a UNION operator.

Рішення ціє несправедливості є. І воно не надто складне: Тригер `instead of`

```sql
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
```

Тепер жодних помилок. 

```sql
INSERT inf.sql_statistic_logical_disk (sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb)
VALUES (1,	1,	1,	1,	'2022-09-22 00:33:42',	0, 	1,	1)
```

Навіть приємний бонус. Можна завжди вставляти, або завжди оновлювати, і не потрібно перевіряти чи такий запис існую чі ні.
Обидва запити виконаються без помилок, і результат буде однаковий.

```sql
INSERT inf.sql_statistic_logical_disk (sqls_id, cluster_id, machine_id, disk_id, dt, collection_date, free_gb, total_gb)
VALUES (1,	1,	1,	1,	'2022-09-22 00:33:42',	0, 	1,	2)

UPDATE inf.sql_statistic_logical_disk
SET total_gb=2
WHERE dt>='2020-02-26'
	AND disk_id=45 
	AND collection_date=637183069253209165

```

І останнє. Видалення.

```sql
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
```

Тепер - все круто.

```sql
SELECT  * FROM inf.sql_statistic_logical_disk WHERE sqls_id = 1 AND disk_id=1 AND collection_date=0 
GO
DELETE FROM inf.sql_statistic_logical_disk WHERE sqls_id = 1 AND disk_id=1 AND collection_date=0 
GO
SELECT  * FROM inf.sql_statistic_logical_disk WHERE sqls_id = 1 AND disk_id=1 AND collection_date=0 
```

І прошу зауважити, жодних змін у коді самого сервісу. Таким чином рішення підійде навіть для EF 

> [!IMPORTANT]
> EF не привід обмежувати фантазію, що, я на жаль, сьогодні спостерігаю, ледь не у більшості розробників