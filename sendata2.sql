 use BaseInterconnexion
 
 --DECLARE @lock_result int;
 --   EXEC @lock_result = sys.sp_getapplock
 --       @Resource = N'dbo.sendata2',
 --       @LockMode = N'Exclusive',
 --       @LockOwner = N'Session',
 --       @LockTimeout = 0;

 --   IF @lock_result < 0
 --       RETURN;

 declare @nb2 int = 0
		select @nb2 = count(*) from Historique_Transactions


		
		--select * from Historique_Transactions
		print  'step  ******** avant : '+convert(varchar(max),@nb2)

		--select top 100 * from p00004030 order by recno desc
		--select * from mapping_windows_web where config_base = '9' and tab_web = 'p00001040'

  	IF OBJECT_ID('tempdb..#work') IS NOT NULL DROP TABLE #work;
    IF OBJECT_ID('tempdb..#group_recno') IS NOT NULL DROP TABLE #group_recno;
    CREATE TABLE #work
    (
        HistId bigint NOT NULL,
        OperationType varchar(20) NOT NULL,
        NomTable sysname NOT NULL,
        Recno decimal(38,0) NULL,
        num_id varchar(max) NULL,
        bd_name sysname NOT NULL,
        cod_config varchar(10) NOT NULL
    );

	print  'step 1'
    INSERT #work (HistId, OperationType, NomTable, Recno, num_id, bd_name, cod_config)
    SELECT TOP (10) HistId, OperationType, NomTable, Recno, num_id, bd_name, cod_config
    FROM dbo.Historique_Transactions
    ORDER BY HistId;

    CREATE TABLE #group_recno (recno decimal(38,0) NOT NULL PRIMARY KEY);

    DECLARE
        @OperationType varchar(20), @NomTable sysname, @bd_name sysname,
        @cod_config varchar(10), @db_windows sysname, @db_web sysname,
        @db_source sysname, @db_dest sysname, @table_source sysname,
        @table_dest sysname, @cols_source varchar(max), @cols_dest varchar(max),
        @id_table varchar(max), @source_is_windows bit, @franchise bit = 0,
        @vcod_cach varchar(4) = '01', @sql nvarchar(max), @join_keys nvarchar(max),
        @source_projection nvarchar(max), @dest_projection nvarchar(max),
        @insert_cols nvarchar(max), @where_keys nvarchar(max), @delete_where nvarchar(max),
        @ids varchar(max), @message nvarchar(2048), @hist_count int;
		

		

    DECLARE work_groups CURSOR LOCAL FAST_FORWARD FOR
        SELECT OperationType, NomTable, bd_name, cod_config
        FROM #work
        GROUP BY OperationType, NomTable, bd_name, cod_config
        ORDER BY CASE OperationType WHEN 'DELETE' THEN 1 WHEN 'UPDATE' THEN 2
                                    WHEN 'INSERT' THEN 3 ELSE 4 END,
                 cod_config, bd_name, NomTable;

				 	print  'step 2'
    OPEN work_groups;
    FETCH NEXT FROM work_groups INTO @OperationType, @NomTable, @bd_name, @cod_config;
	
    WHILE @@FETCH_STATUS = 0
    BEGIN
		print  'step **************debut******************'
		print '@OperationType : '+ @OperationType +'|| @NomTable : '+ @NomTable +'|| @bd_name : '+ @bd_name +'|| @NomTable : '+ @NomTable
   
        SET @db_windows = NULL; SET @db_web = NULL;
        SELECT @db_windows = NULLIF(LTRIM(RTRIM(db_source)), N''),
               @db_web = NULLIF(LTRIM(RTRIM(db_dest)), N'')
        FROM dbo.wconfig_base()
        WHERE cod_config = @cod_config;

		
        SET @source_is_windows = CASE WHEN @bd_name = @db_windows THEN 1 ELSE 0 END;
        SET @db_source = CASE WHEN @source_is_windows = 1 THEN @db_windows ELSE @db_web END;
        SET @db_dest = CASE WHEN @source_is_windows = 1 THEN @db_web ELSE @db_windows END;
        SET @table_source = @NomTable;
        SET @table_dest = NULL; SET @cols_source = NULL; SET @cols_dest = NULL; SET @id_table = NULL;

		--select * FROM dbo.mapping_windows_web where tab_window = 'b00006210' and config_base = '9'
        IF @db_source IS NULL OR @db_dest IS NULL
            SET @message = CONCAT(N'Configuration de bases introuvable: ', @cod_config);
        ELSE
        BEGIN
		    SELECT TOP (1)
                @table_dest = CASE WHEN @source_is_windows = 1 THEN LTRIM(RTRIM(tab_web)) ELSE LTRIM(RTRIM(tab_window)) END,
                @cols_source = CASE WHEN @source_is_windows = 1 THEN LTRIM(RTRIM(col_window)) ELSE LTRIM(RTRIM(col_web)) END,
                @cols_dest = CASE WHEN @source_is_windows = 1 THEN LTRIM(RTRIM(col_web)) ELSE LTRIM(RTRIM(col_window)) END,
                @id_table = id_table
            FROM dbo.mapping_windows_web
            WHERE config_base = @cod_config
              AND ((@source_is_windows = 1 AND tab_window = @NomTable)
                OR (@source_is_windows = 0 AND tab_web = @NomTable))
            ORDER BY id_table;

            SET @message = NULL;
            IF @table_dest IS NULL OR @cols_source IS NULL OR @cols_dest IS NULL OR @id_table IS NULL
                SET @message = CONCAT(N'Mapping absent/incomplet pour ', @NomTable, N' / ', @cod_config);
        END;
		print '>>>>>>>>>>@message : '+ @message
        IF @message IS NOT NULL
        BEGIN
            INSERT dbo.p00004030(lib_err, franchise, date_err, heure_err)
            VALUES (@NomTable+' : '+@message, @franchise, GETDATE(), CONVERT(time, GETDATE()));
			
		print  'step **************fin******************'

            FETCH NEXT FROM work_groups INTO @OperationType, @NomTable, @bd_name, @cod_config;
            CONTINUE;
        END;

        /* Construire les listes SQL à partir des paramètres de mapping. */
        SELECT @source_projection = STRING_AGG(QUOTENAME(LTRIM(RTRIM(value))), N',') WITHIN GROUP (ORDER BY ordinal)
        FROM STRING_SPLIT(@cols_source, ',', 1)
        WHERE LTRIM(RTRIM(value)) <> '' AND LTRIM(RTRIM(value)) NOT IN ('recno','franchise');
        SELECT @dest_projection = STRING_AGG(QUOTENAME(LTRIM(RTRIM(value))), N',') WITHIN GROUP (ORDER BY ordinal)
        FROM STRING_SPLIT(@cols_dest, ',', 1)
        WHERE LTRIM(RTRIM(value)) <> '' AND LTRIM(RTRIM(value)) NOT IN ('recno','franchise');

        IF @source_projection IS NULL OR @dest_projection IS NULL
        BEGIN
            INSERT dbo.p00004030(lib_err, franchise, date_err, heure_err)
            VALUES (CONCAT(N'Colonnes de mapping vides pour ', @NomTable), @franchise, GETDATE(), CONVERT(time, GETDATE()));
			print CONCAT(N'>>>>>>>>>> Colonnes de mapping vides pour ', @NomTable)

			
		print  'step **************fin 10******************'

            FETCH NEXT FROM work_groups INTO @OperationType, @NomTable, @bd_name, @cod_config;
            CONTINUE;
        END;

        SELECT @join_keys = STRING_AGG(N'd.' + QUOTENAME(LTRIM(RTRIM(value))) + N' = s.' + QUOTENAME(LTRIM(RTRIM(value))), N' AND '),
               @where_keys = STRING_AGG(N's.' + QUOTENAME(LTRIM(RTRIM(value))) + N' IS NOT NULL', N' AND ')
        FROM STRING_SPLIT(REPLACE(@id_table, '|', ','), ',')
        WHERE LTRIM(RTRIM(value)) <> '';
        IF @join_keys IS NULL
        BEGIN
            INSERT dbo.p00004030(lib_err, franchise, date_err, heure_err)
            VALUES (CONCAT(N'Clé de mapping vide pour ', @NomTable), @franchise, GETDATE(), CONVERT(time, GETDATE()));
			print CONCAT(N' >>>>>>>>>> Clé de mapping vide pour ', @NomTable)

			
		print  'step **************debut******************'

            FETCH NEXT FROM work_groups INTO @OperationType, @NomTable, @bd_name, @cod_config;
            CONTINUE;
        END;

        SET @insert_cols = @dest_projection;
        IF @source_is_windows = 1
            SET @insert_cols += N',[franchise]';

        BEGIN TRY
            TRUNCATE TABLE #group_recno;
            BEGIN TRANSACTION;

            INSERT #group_recno(recno)
            SELECT DISTINCT Recno FROM #work
            WHERE OperationType = @OperationType AND NomTable = @NomTable
              AND bd_name = @bd_name AND cod_config = @cod_config AND Recno IS NOT NULL;

            SELECT @hist_count = COUNT(*) FROM #work
            WHERE OperationType = @OperationType AND NomTable = @NomTable
              AND bd_name = @bd_name AND cod_config = @cod_config;

            /* Désactivation dans la même transaction; rollback restaure l'état en cas d'erreur. */
            SET @sql = N'UPDATE ' + QUOTENAME(@db_dest) + N'.dbo.Config_Trigger SET is_active = 0 WHERE table_name = @p_table;';
            EXEC sys.sp_executesql @sql, N'@p_table sysname', @p_table = @table_dest;

            IF @OperationType IN ('INSERT','UPDATE')
            BEGIN
			print  'INSERT or UPDATE'
                /* DELETE destination en joignant les clés métier à la source.
                   Cela préserve la correspondance même si les identity recno diffèrent. */
                SET @sql = N'DELETE d FROM ' + QUOTENAME(@db_dest) + N'.dbo.' + QUOTENAME(@table_dest) + N' AS d
                    WHERE EXISTS (SELECT 1 FROM ' + QUOTENAME(@db_source) + N'.dbo.' + QUOTENAME(@table_source) + N' AS s
                    WHERE ' + @join_keys + N' AND EXISTS (SELECT 1 FROM #group_recno r WHERE r.recno = s.recno));';
					print @sql
                EXEC sys.sp_executesql @sql;

                SET @sql = N'INSERT INTO ' + QUOTENAME(@db_dest) + N'.dbo.' + QUOTENAME(@table_dest) + N' (' + @insert_cols + N')
                    SELECT ' + @source_projection
                    + CASE WHEN @source_is_windows = 1 THEN N',@p_franchise' ELSE N'' END
                    + N' FROM ' + QUOTENAME(@db_source) + N'.dbo.' + QUOTENAME(@table_source) + N' AS s
                    WHERE EXISTS (SELECT 1 FROM #group_recno r WHERE r.recno = s.recno);';
					print @sql
                EXEC sys.sp_executesql @sql, N'@p_franchise bit', @p_franchise = @franchise;
            END
            ELSE IF @OperationType = 'DELETE'
            BEGIN
			print  'DELETE'
                ;WITH ids_uniques AS
                (
                    SELECT DISTINCT LTRIM(RTRIM(num_id)) AS num_id
                    FROM #work
                    WHERE OperationType = @OperationType AND NomTable = @NomTable
                      AND bd_name = @bd_name AND cod_config = @cod_config
                      AND NULLIF(LTRIM(RTRIM(num_id)), '') IS NOT NULL
                )
                SELECT @ids = STRING_AGG(num_id, ',') FROM ids_uniques;

				    print '@ids : ' + @ids
				  print '@id_table : ' + @id_table
                SET @delete_where = dbo.fn_GenerateWhere2(@id_table, @ids);

				print '@delete_where : ' + @delete_where

                IF NULLIF(LTRIM(RTRIM(@delete_where)), N'') IS NULL
                    THROW 51001, 'La fonction fn_GenerateWhere2 n''a pas produit de condition de suppression.', 1;
                SET @sql = N'DELETE FROM ' + QUOTENAME(@db_dest) + N'.dbo.' + QUOTENAME(@table_dest) + N' WHERE ' + @delete_where + N';';
				 print @sql
                EXEC sys.sp_executesql @sql;
            END
            ELSE
                THROW 51002, 'Type d''operation non reconnu dans Historique_Transactions.', 1;

            SET @sql = N'UPDATE ' + QUOTENAME(@db_dest) + N'.dbo.Config_Trigger SET is_active = 1 WHERE table_name = @p_table;';
            EXEC sys.sp_executesql @sql, N'@p_table sysname', @p_table = @table_dest;

            DELETE h
            FROM dbo.Historique_Transactions AS h
            INNER JOIN #work AS w ON w.HistId = h.HistId
            WHERE w.OperationType = @OperationType AND w.NomTable = @NomTable
              AND w.bd_name = @bd_name AND w.cod_config = @cod_config;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            INSERT dbo.p00004030(lib_err, franchise, date_err, heure_err)
            VALUES (CONCAT(@NomTable, N' : ', ERROR_MESSAGE()), @franchise, GETDATE(), CONVERT(time, GETDATE()));

			print '>>>>>>>>>> '+ERROR_MESSAGE()+' <<<<<<<<<<<<<'
            print '>>>>>>>>>> SQL en erreur : '+COALESCE(@sql, N'<SQL non construit>')+' <<<<<<<<<<<<<'
        END CATCH;

		declare @nb int = 0
		select @nb = count(*) from Historique_Transactions

		print  'step **************fin end****************** reste : '+convert(varchar(max),@nb)

        FETCH NEXT FROM work_groups INTO @OperationType, @NomTable, @bd_name, @cod_config;
    END;

    CLOSE work_groups;
    DEALLOCATE work_groups;
    --EXEC sys.sp_releaseapplock @Resource = N'dbo.sendata2', @LockOwner = N'Session';
