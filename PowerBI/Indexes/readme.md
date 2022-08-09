# readme

- Статистика использования индекса (seeks, scans, updates) и операционная статистика (latch, lock wait)
- Cведения об отсутствующих индексах
- Объекты в буферном пуле (памяти)
- Размер таблиц на диске (с разбивкой на файловые группы)

​​​​​​​Этот дашборд поможет нагядно и быстро оценить состояние индексов в базе.

Рекомендуется, также, освежить в памяти (или прочитать) руководство по проектирования индексов,
или пройти модуль Проектирование на основе производительности. ​​​​​​​
​​​​​​​Ни то ни другое не должно отнять у вас больше часа.

### Если не установлен Power BI:

+ [Можно скачать и поставить](https://powerbi.microsoft.com/ru-ru/desktop/)
+ [Установить из Microsoft Store](https://www.microsoft.com/store/productId/9NTXR16HNW1T)

Или набрать в powershell
```powershell
winget install powerbi
```

> Требуется доступ к системным представлениям
> - sys.dm_db_index_usage_stats
> - sys.dm_db_index_operational_stats 
> - sys.dm_db_missing_index_columns
> - sys.dm_db_missing_index_details
> - sys.dm_db_missing_index_groups
> - sys.dm_db_missing_index_group_stats
> - sys.dm_os_buffer_descriptors
> - sys.objects
> - sys.indexes
> - sys.allocation_units
> - sys.partitions
> - sys.filegroups