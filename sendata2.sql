USE [BaseInterconnexion];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

--DECLARE @lock_result int;
--EXEC @lock_result = sys.sp_getapplock
--    @Resource = N'dbo.sendata2',
--    @LockMode = N'Exclusive',
--    @LockOwner = N'Session',
--    @LockTimeout = 0;
--IF @lock_result < 0 RETURN;

DECLARE @nb2 int = 0;
SELECT @nb2 = COUNT(*) FROM dbo.Historique_Transactions;
PRINT N'step  ******** avant : ' + CONVERT(varchar(max), @nb2);

IF OBJECT_ID('tempdb..#work') IS NOT NULL DROP TABLE #work;
IF OBJECT_ID('tempdb..#group_recno') IS NOT NULL DROP TABLE #group_recno;
IF OBJECT_ID('tempdb..#map_work') IS NOT NULL DROP TABLE #map_work;
IF OBJECT_ID('tempdb..#pair_cols') IS NOT NULL DROP TABLE #pair_cols;

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

PRINT N'step 1';
-- TOP (10) est conservé pour vos traitements progressifs de validation.
INSERT #work (HistId, OperationType, NomTable, Recno, num_id, bd_name, cod_config)
SELECT  HistId, OperationType, NomTable, Recno, num_id, bd_name, cod_config
FROM dbo.Historique_Transactions
ORDER BY HistId;


CREATE TABLE #group_recno (recno decimal(38,0) NOT NULL PRIMARY KEY);
CREATE TABLE #map_work
(
    MappingId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    tab_window sysname NOT NULL,
    tab_web sysname NOT NULL,
    col_window nvarchar(max) NULL,
    col_web nvarchar(max) NULL,
    id_table nvarchar(max) NULL
);
CREATE TABLE #pair_cols
(
    ordinal int NOT NULL,
    source_column sysname NOT NULL,
    dest_column sysname NOT NULL
);

DECLARE
    @OperationType varchar(20), @NomTable sysname, @bd_name sysname,
    @cod_config varchar(10), @db_windows sysname, @db_web sysname,
    @db_source sysname, @db_dest sysname, @table_source sysname,
    @table_dest sysname, @cols_source nvarchar(max), @cols_dest nvarchar(max),
    @id_table nvarchar(max), @source_is_windows bit, @franchise bit = 0,
    @sql nvarchar(max), @join_keys nvarchar(max), @source_projection nvarchar(max),
    @dest_projection nvarchar(max), @insert_cols nvarchar(max), @update_set nvarchar(max),
    @delete_where nvarchar(max), @ids nvarchar(max), @message nvarchar(2048),
    @source_column_count int, @dest_column_count int, @dest_has_franchise bit,
    @orphan_extension bit, @nb int;

DECLARE work_groups CURSOR LOCAL FAST_FORWARD FOR
    SELECT OperationType, NomTable, bd_name, cod_config
    FROM #work
    GROUP BY OperationType, NomTable, bd_name, cod_config
    ORDER BY CASE OperationType WHEN 'DELETE' THEN 1 WHEN 'UPDATE' THEN 2
                                WHEN 'INSERT' THEN 3 ELSE 4 END,
             cod_config, bd_name, NomTable;

PRINT N'step 2';
OPEN work_groups;
FETCH NEXT FROM work_groups INTO @OperationType, @NomTable, @bd_name, @cod_config;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT N'step **************debut******************';
    PRINT N'@OperationType : ' + @OperationType + N'|| @NomTable : ' + @NomTable
        + N'|| @bd_name : ' + @bd_name + N'|| @cod_config : ' + @cod_config;

    SET @db_windows = NULL;
    SET @db_web = NULL;
    SELECT @db_windows = NULLIF(LTRIM(RTRIM(db_source)), N''),
           @db_web = NULLIF(LTRIM(RTRIM(db_dest)), N'')
    FROM dbo.wconfig_base()
    WHERE cod_config = @cod_config;

    SET @source_is_windows = CASE WHEN @bd_name = @db_windows THEN 1
                                  WHEN @bd_name = @db_web THEN 0 ELSE NULL END;
    SET @db_source = CASE WHEN @source_is_windows = 1 THEN @db_windows ELSE @db_web END;
    SET @db_dest = CASE WHEN @source_is_windows = 1 THEN @db_web ELSE @db_windows END;
    SET @table_source = @NomTable;
    SET @message = NULL;
    DELETE FROM #map_work;

    IF @db_windows IS NULL OR @db_web IS NULL OR @source_is_windows IS NULL
        SET @message = CONCAT(N'Configuration ou base source introuvable: ', @cod_config,
                              N' / ', @bd_name);
    ELSE
    BEGIN
        /* Charger TOUTES les correspondances, au lieu de choisir TOP (1). */
        INSERT #map_work(tab_window, tab_web, col_window, col_web, id_table)
        SELECT LTRIM(RTRIM(tab_window)), LTRIM(RTRIM(tab_web)),
               NULLIF(LTRIM(RTRIM(col_window)), N''),
               NULLIF(LTRIM(RTRIM(col_web)), N''),
               NULLIF(LTRIM(RTRIM(id_table)), N'')
        FROM dbo.mapping_windows_web
        WHERE config_base = @cod_config
          AND ((@source_is_windows = 1 AND tab_window = @NomTable)
            OR (@source_is_windows = 0 AND tab_web = @NomTable));

        IF NOT EXISTS (SELECT 1 FROM #map_work)
            SET @message = CONCAT(N'Mapping absent pour ', @NomTable, N' / ', @cod_config);
    END;

    PRINT N'>>>>>>>>>>@message : ' + COALESCE(@message, N'<aucune>');
    IF @message IS NOT NULL
    BEGIN
        INSERT dbo.p00004030(lib_err, franchise, date_err, heure_err)
        VALUES (CONCAT(@NomTable, N' : ', @message), @franchise, GETDATE(), CONVERT(time, GETDATE()));
        PRINT N'step **************fin******************';
        FETCH NEXT FROM work_groups INTO @OperationType, @NomTable, @bd_name, @cod_config;
        CONTINUE;
    END;

    BEGIN TRY
        TRUNCATE TABLE #group_recno;
        BEGIN TRANSACTION;

        INSERT #group_recno(recno)
        SELECT DISTINCT Recno
        FROM #work
        WHERE OperationType = @OperationType AND NomTable = @NomTable
          AND bd_name = @bd_name AND cod_config = @cod_config AND Recno IS NOT NULL;

        IF @OperationType IN ('INSERT','UPDATE') AND NOT EXISTS (SELECT 1 FROM #group_recno)
        BEGIN
            THROW 51010, 'Aucun recno source disponible pour INSERT/UPDATE.', 1;
        END;

        DECLARE map_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT CASE WHEN @source_is_windows = 1 THEN tab_web ELSE tab_window END,
                   CASE WHEN @source_is_windows = 1 THEN col_window ELSE col_web END,
                   CASE WHEN @source_is_windows = 1 THEN col_web ELSE col_window END,
                   id_table
            FROM #map_work
            ORDER BY CASE
                        WHEN @OperationType = 'DELETE' AND @source_is_windows = 1
                            THEN CASE WHEN tab_window = tab_web THEN 1 ELSE 0 END
                        ELSE CASE WHEN tab_window = tab_web THEN 0 ELSE 1 END
                     END,
                     tab_web, tab_window;

        OPEN map_cursor;
        FETCH NEXT FROM map_cursor INTO @table_dest, @cols_source, @cols_dest, @id_table;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT N'----- Mapping destination : ' + COALESCE(@table_dest, N'<NULL>')
                + N' | Source : ' + COALESCE(@table_source, N'<NULL>');

            IF @table_dest IS NULL OR @cols_source IS NULL OR @cols_dest IS NULL OR @id_table IS NULL
            BEGIN
                THROW 51011, 'Mapping incomplet: table, colonnes ou identifiant manquant.', 1;
            END;

            /* Une suppression d'extension Web ne doit pas supprimer la ligne parent Windows. */
            IF @OperationType = 'DELETE' AND @source_is_windows = 0
               AND @NomTable <> @table_dest
            BEGIN
                PRINT N'DELETE Web d''extension ignore pour la ligne Windows parente : ' + @NomTable;
                FETCH NEXT FROM map_cursor INTO @table_dest, @cols_source, @cols_dest, @id_table;
                CONTINUE;
            END;

            SET @source_projection = NULL;
            SET @dest_projection = NULL;
            SET @update_set = NULL;
            SET @insert_cols = NULL;
            SET @join_keys = NULL;
            SET @delete_where = NULL;
            SET @ids = NULL;
            DELETE FROM #pair_cols;

            SET @source_column_count = (SELECT COUNT(*) FROM STRING_SPLIT(@cols_source, N',')
                                        WHERE LTRIM(RTRIM(value)) <> N'' AND LOWER(LTRIM(RTRIM(value))) NOT IN (N'recno',N'franchise'));
            SET @dest_column_count = (SELECT COUNT(*) FROM STRING_SPLIT(@cols_dest, N',')
                                      WHERE LTRIM(RTRIM(value)) <> N'' AND LOWER(LTRIM(RTRIM(value))) NOT IN (N'recno',N'franchise'));
            IF @source_column_count = 0 OR @dest_column_count = 0 OR @source_column_count <> @dest_column_count
            BEGIN
                THROW 51012, 'Le nombre de colonnes source et destination est vide ou different dans le mapping.', 1;
            END;

            INSERT #pair_cols(ordinal, source_column, dest_column)
            SELECT s.ordinal, LTRIM(RTRIM(s.value)), LTRIM(RTRIM(d.value))
            FROM STRING_SPLIT(@cols_source, N',', 1) AS s
            INNER JOIN STRING_SPLIT(@cols_dest, N',', 1) AS d ON d.ordinal = s.ordinal
            WHERE LTRIM(RTRIM(s.value)) <> N'' AND LTRIM(RTRIM(d.value)) <> N''
              AND LOWER(LTRIM(RTRIM(s.value))) NOT IN (N'recno',N'franchise')
              AND LOWER(LTRIM(RTRIM(d.value))) NOT IN (N'recno',N'franchise');

            IF (SELECT COUNT(*) FROM #pair_cols) <> @source_column_count
            BEGIN
                THROW 51013, 'Les listes de colonnes ne sont pas alignees par position.', 1;
            END;

            SELECT @source_projection = STRING_AGG(CONVERT(nvarchar(max), N's.' + QUOTENAME(source_column)), N',') WITHIN GROUP (ORDER BY ordinal),
                   @dest_projection = STRING_AGG(CONVERT(nvarchar(max), QUOTENAME(dest_column)), N',') WITHIN GROUP (ORDER BY ordinal),
                   @update_set = STRING_AGG(CONVERT(nvarchar(max), N'd.' + QUOTENAME(dest_column) + N' = s.' + QUOTENAME(source_column)), N',') WITHIN GROUP (ORDER BY ordinal)
            FROM #pair_cols;

            SELECT @join_keys = STRING_AGG(CONVERT(nvarchar(max), N'd.' + QUOTENAME(LTRIM(RTRIM(value)))
                                         + N' = s.' + QUOTENAME(LTRIM(RTRIM(value)))), N' AND ')
            FROM STRING_SPLIT(REPLACE(@id_table, N'|', N','), N',')
            WHERE LTRIM(RTRIM(value)) <> N'';
            IF @join_keys IS NULL
            BEGIN
                THROW 51014, 'Cle de correspondance vide dans le mapping.', 1;
            END;

            SET @dest_has_franchise = 0;
            SET @sql = N'SELECT @p_has = CASE WHEN EXISTS
                (SELECT 1 FROM ' + QUOTENAME(@db_dest) + N'.sys.tables t
                 JOIN ' + QUOTENAME(@db_dest) + N'.sys.schemas sc ON sc.schema_id=t.schema_id
                 JOIN ' + QUOTENAME(@db_dest) + N'.sys.columns c ON c.object_id=t.object_id
                 WHERE sc.name=N''dbo'' AND t.name=@p_table AND c.name=N''franchise'')
                THEN 1 ELSE 0 END;';
            EXEC sys.sp_executesql @sql, N'@p_table sysname,@p_has bit OUTPUT',
                @p_table = @table_dest, @p_has = @dest_has_franchise OUTPUT;

            SET @insert_cols = @dest_projection;
            IF @source_is_windows = 1 AND @dest_has_franchise = 1
                SET @insert_cols += N',[franchise]';

            /* Eviter de re-déclencher la file sur la table cible pendant son écriture. */
            SET @sql = N'UPDATE ' + QUOTENAME(@db_dest)
                + N'.dbo.Config_Trigger SET is_active=0 WHERE table_name=@p_table;';
            EXEC sys.sp_executesql @sql, N'@p_table sysname', @p_table = @table_dest;

            IF @OperationType IN ('INSERT','UPDATE')
            BEGIN
                PRINT N'INSERT or UPDATE - upsert colonnes mappees';
                SET @sql = N'UPDATE d SET ' + @update_set
                    + N' FROM ' + QUOTENAME(@db_dest) + N'.dbo.' + QUOTENAME(@table_dest) + N' AS d'
                    + N' INNER JOIN ' + QUOTENAME(@db_source) + N'.dbo.' + QUOTENAME(@table_source) + N' AS s ON ' + @join_keys
                    + N' WHERE EXISTS (SELECT 1 FROM #group_recno r WHERE r.recno=s.recno);';
                PRINT @sql;
                EXEC sys.sp_executesql @sql;

                IF @source_is_windows = 0 AND @NomTable <> @table_dest
                BEGIN
                    /* Une extension Web ne crée jamais un parent Windows manquant. */
                    SET @orphan_extension = 0;
                    SET @sql = N'SELECT @p_orphan = CASE WHEN EXISTS (SELECT 1 FROM ' + QUOTENAME(@db_source) + N'.dbo.' + QUOTENAME(@table_source) + N' AS s'
                        + N' WHERE EXISTS (SELECT 1 FROM #group_recno r WHERE r.recno=s.recno)'
                        + N' AND NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@db_dest) + N'.dbo.' + QUOTENAME(@table_dest) + N' AS d WHERE ' + @join_keys + N'))'
                        + N' THEN 1 ELSE 0 END;';
                    PRINT @sql;
                    EXEC sys.sp_executesql @sql, N'@p_orphan bit OUTPUT', @p_orphan = @orphan_extension OUTPUT;
                    IF @orphan_extension = 1
                    BEGIN
                        THROW 51015, 'Extension Web sans ligne parente Windows.', 1;
                    END;
                END
                ELSE
                BEGIN
                    SET @sql = N'INSERT INTO ' + QUOTENAME(@db_dest) + N'.dbo.' + QUOTENAME(@table_dest)
                        + N' (' + @insert_cols + N') SELECT ' + @source_projection
                        + CASE WHEN @source_is_windows = 1 AND @dest_has_franchise = 1 THEN N',@p_franchise' ELSE N'' END
                        + N' FROM ' + QUOTENAME(@db_source) + N'.dbo.' + QUOTENAME(@table_source) + N' AS s'
                        + N' WHERE EXISTS (SELECT 1 FROM #group_recno r WHERE r.recno=s.recno)'
                        + N' AND NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@db_dest) + N'.dbo.' + QUOTENAME(@table_dest) + N' AS d WHERE ' + @join_keys + N');';
                    PRINT @sql;
                    EXEC sys.sp_executesql @sql, N'@p_franchise bit', @p_franchise = @franchise;
                END;
            END
            ELSE IF @OperationType = 'DELETE'
            BEGIN
                PRINT N'DELETE';
                ;WITH ids_uniques AS
                (
                    SELECT DISTINCT LTRIM(RTRIM(num_id)) AS num_id
                    FROM #work
                    WHERE OperationType = @OperationType AND NomTable = @NomTable
                      AND bd_name = @bd_name AND cod_config = @cod_config
                      AND NULLIF(LTRIM(RTRIM(num_id)), N'') IS NOT NULL
                )
                SELECT @ids = STRING_AGG(num_id, N',') FROM ids_uniques;
                PRINT N'@ids : ' + COALESCE(@ids, N'<NULL>');
                PRINT N'@id_table : ' + @id_table;

                IF NULLIF(LTRIM(RTRIM(@ids)), N'') IS NULL
                BEGIN
                    THROW 51016, 'Aucune valeur num_id disponible pour DELETE.', 1;
                END;
                SET @delete_where = dbo.fn_GenerateWhere2(@id_table, @ids);
                PRINT N'@delete_where : ' + COALESCE(@delete_where, N'<NULL>');
                IF NULLIF(LTRIM(RTRIM(@delete_where)), N'') IS NULL
                BEGIN
                    THROW 51017, 'La fonction fn_GenerateWhere2 n''a pas produit de condition de suppression.', 1;
                END;

                SET @sql = N'DELETE FROM ' + QUOTENAME(@db_dest) + N'.dbo.' + QUOTENAME(@table_dest)
                    + N' WHERE ' + @delete_where + N';';
                PRINT @sql;
                EXEC sys.sp_executesql @sql;
            END
            ELSE
                THROW 51018, 'Type d''operation non reconnu dans Historique_Transactions.', 1;

            SET @sql = N'UPDATE ' + QUOTENAME(@db_dest)
                + N'.dbo.Config_Trigger SET is_active=1 WHERE table_name=@p_table;';
            EXEC sys.sp_executesql @sql, N'@p_table sysname', @p_table = @table_dest;

            PRINT N'----- Fin mapping destination : ' + @table_dest;
            FETCH NEXT FROM map_cursor INTO @table_dest, @cols_source, @cols_dest, @id_table;
        END;

        CLOSE map_cursor;
        DEALLOCATE map_cursor;

        /* Retirer uniquement les événements du groupe après réussite de tous les mappings. */
        DELETE h
        FROM dbo.Historique_Transactions AS h
        INNER JOIN #work AS w ON w.HistId = h.HistId
        WHERE w.OperationType = @OperationType AND w.NomTable = @NomTable
          AND w.bd_name = @bd_name AND w.cod_config = @cod_config;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'map_cursor') >= 0 CLOSE map_cursor;
        IF CURSOR_STATUS('local', 'map_cursor') >= -1 DEALLOCATE map_cursor;
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        INSERT dbo.p00004030(lib_err, franchise, date_err, heure_err)
        VALUES (CONCAT(@NomTable, N' : ', ERROR_MESSAGE()), @franchise, GETDATE(), CONVERT(time, GETDATE()));
        PRINT N'>>>>>>>>>> ' + ERROR_MESSAGE() + N' <<<<<<<<<<<<<';
        PRINT N'>>>>>>>>>> SQL en erreur : ' + COALESCE(@sql, N'<SQL non construit>') + N' <<<<<<<<<<<<<';
    END CATCH;

    SET @nb = 0;
    SELECT @nb = COUNT(*) FROM dbo.Historique_Transactions;
    PRINT N'step **************fin end****************** reste : ' + CONVERT(varchar(max), @nb);

    FETCH NEXT FROM work_groups INTO @OperationType, @NomTable, @bd_name, @cod_config;
END;

CLOSE work_groups;
DEALLOCATE work_groups;
--EXEC sys.sp_releaseapplock @Resource = N'dbo.sendata2', @LockOwner = N'Session';
GO
