USE [BaseInterconnexion];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

/*
    Synchronisation des changements de Historique_Transactions.

    Fonctionnement général :
      1. Copier un instantané des événements à traiter dans #work.
      2. Regrouper les événements par opération, table source, base et configuration.
      3. Charger toutes les correspondances de la table source, pas seulement la
         première : une table Windows peut ainsi alimenter une table Web principale
         et une ou plusieurs tables Web d'extension.
      4. Pour chaque correspondance, synchroniser seulement les colonnes configurées.
      5. Supprimer les événements de l'historique uniquement si toutes les
         correspondances du groupe ont réussi.

    Les listes col_window et col_web de mapping_windows_web doivent être séparées
    par des virgules et alignées par position. id_table doit désigner les mêmes
    colonnes de clé côté source et côté destination. Les colonnes recno et
    franchise ne sont pas copiées par le mapping standard.

    Aucun filtre n'est appliqué au chargement de l'historique : #work reçoit tous
    les événements présents au démarrage.
*/

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

/* Instantané stable des événements. HistId permet de supprimer seulement les
   événements effectivement capturés, sans effacer ceux ajoutés ensuite. */
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
INSERT #work (HistId, OperationType, NomTable, Recno, num_id, bd_name, cod_config)
SELECT  HistId, OperationType, NomTable, Recno, num_id, bd_name, cod_config
FROM dbo.Historique_Transactions
ORDER BY HistId;

/* Liste des recno source du groupe courant. recno n'est jamais utilisé comme
   identifiant commun entre les deux bases : il ne filtre que la base source. */
CREATE TABLE #group_recno (recno decimal(38,0) NOT NULL PRIMARY KEY);

/* Correspondances de mapping applicables au groupe. #map_work peut contenir
   plusieurs destinations pour la même table source (table principale + extensions). */
CREATE TABLE #map_work
(
    MappingId int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    tab_window sysname NOT NULL,
    tab_web sysname NOT NULL,
    col_window nvarchar(max) NULL,
    col_web nvarchar(max) NULL,
    id_table nvarchar(max) NULL
);

/* Paires de colonnes construites à partir des listes col_window/col_web.
   ordinal conserve l'association de chaque colonne source à sa destination. */
CREATE TABLE #pair_cols
(
    ordinal int NOT NULL,
    source_column sysname NOT NULL,
    dest_column sysname NOT NULL
);

/* Variables du groupe d'événements et sens de réplication. @source_is_windows = 1
   signifie Windows -> Web; 0 signifie Web -> Windows. @db_source/@db_dest et
   @table_source/@table_dest sont recalculés pour chaque groupe/correspondance. */
DECLARE
    @OperationType varchar(20), @NomTable sysname, @bd_name sysname,
    @cod_config varchar(10), @db_windows sysname, @db_web sysname,
    @db_source sysname, @db_dest sysname, @table_source sysname,
    @table_dest sysname, @cols_source nvarchar(max), @cols_dest nvarchar(max),
    @id_table nvarchar(max), @source_is_windows bit, @franchise bit = 0,
    @vcod_cach varchar(4) = '01',
    @sql nvarchar(max), @join_keys nvarchar(max), @source_projection nvarchar(max),
    @dest_projection nvarchar(max), @insert_cols nvarchar(max), @update_set nvarchar(max),
    @delete_where nvarchar(max), @ids nvarchar(max), @message nvarchar(2048),
    @source_column_count int, @dest_column_count int, @dest_has_franchise bit,
    @dest_has_cod_cach bit,
    @orphan_extension bit, @nb int,
	@etat int = 0;

/* Un groupe réunit les opérations compatibles sur la même table et dans le même
   sens. Les DELETE sont traités en premier, puis UPDATE et INSERT. */
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

		select @etat = etat2  from BaseInterconnexion.dbo.wconfig_base() where cod_config = @cod_config
		if @etat = 1 --replication désactive
		begin
			print 'replication désactivé'
			return
		end

    PRINT N'step **************debut******************';
    PRINT N'@OperationType : ' + @OperationType + N'|| @NomTable : ' + @NomTable
        + N'|| @bd_name : ' + @bd_name + N'|| @cod_config : ' + @cod_config;

    SET @db_windows = NULL;
    SET @db_web = NULL;
    SELECT @db_windows = NULLIF(LTRIM(RTRIM(db_source)), N''),
           @db_web = NULLIF(LTRIM(RTRIM(db_dest)), N'')
    FROM dbo.wconfig_base()
    WHERE cod_config = @cod_config;

    /* bd_name indique la base qui a produit l'événement; il détermine la direction. */
    SET @source_is_windows = CASE WHEN @bd_name = @db_windows THEN 1
                                  WHEN @bd_name = @db_web THEN 0 ELSE NULL END;
    SET @db_source = CASE WHEN @source_is_windows = 1 THEN @db_windows ELSE @db_web END;
    SET @db_dest = CASE WHEN @source_is_windows = 1 THEN @db_web ELSE @db_windows END;
    SET @table_source = @NomTable;
    SET @message = NULL;
    DELETE FROM #map_work;

    IF @db_windows IS NULL OR @db_web IS NULL OR @source_is_windows IS NULL
        SET @message = CONCAT(N'Configuration ou base source introuvable: ', @cod_config, N' / ', @bd_name);
    ELSE
    BEGIN
        /* Charger toutes les destinations de la table source. En sens Windows -> Web,
           une ligne de mapping est traitée pour chaque table Web correspondante. En
           sens Web -> Windows, les correspondances de la table Web source sont prises. */

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
        INSERT dbo.p00004030(code_err, lib_err, franchise, date_err, heure_err)
        VALUES (51000, CONCAT(@NomTable, N' : ', @message), @franchise, GETDATE(), CONVERT(time, GETDATE()));
        PRINT N'step **************fin******************';
        FETCH NEXT FROM work_groups INTO @OperationType, @NomTable, @bd_name, @cod_config;
        CONTINUE;
    END;

    /* Une transaction couvre le groupe complet et toutes ses destinations. Si un
       mapping échoue, les écritures précédentes du groupe sont annulées et ses
       événements restent dans l'historique pour une nouvelle tentative. */
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

        /* Parcours des correspondances une par une. En Windows -> Web, INSERT/UPDATE
           traitent d'abord la table principale puis ses extensions; DELETE traite
           les extensions avant la table principale. */
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

            /* Une suppression d'extension Web n'est pas une suppression du parent
               Windows. Seule la suppression de la table Web principale est propagée
               comme suppression du parent. */
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

            /* Vérifier les deux listes, puis fabriquer les paires source/destination
               dans l'ordre déclaré par le mapping. recno/franchise sont des champs
               système; en Windows -> Web, cod_cach destination est rempli à '01'. */
            SET @source_column_count = (SELECT COUNT(*) FROM STRING_SPLIT(@cols_source, N',')
                                        WHERE LTRIM(RTRIM(value)) <> N'');
            SET @dest_column_count = (SELECT COUNT(*) FROM STRING_SPLIT(@cols_dest, N',')
                                      WHERE LTRIM(RTRIM(value)) <> N'');
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
              AND LOWER(LTRIM(RTRIM(d.value))) NOT IN (N'recno',N'franchise')
              /* En Windows -> Web, cod_cach est écrit avec la valeur spéciale '01'. */
              AND NOT (@source_is_windows = 1 AND LOWER(LTRIM(RTRIM(d.value))) = N'cod_cach');

            IF NOT EXISTS (SELECT 1 FROM #pair_cols)
            BEGIN
                THROW 51013, 'Aucune colonne mappee exploitable apres exclusion de recno/franchise/cod_cach.', 1;
            END;

            SELECT @source_projection = STRING_AGG(CONVERT(nvarchar(max), N's.' + QUOTENAME(source_column)), N',') WITHIN GROUP (ORDER BY ordinal),
                   @dest_projection = STRING_AGG(CONVERT(nvarchar(max), QUOTENAME(dest_column)), N',') WITHIN GROUP (ORDER BY ordinal),
                   @update_set = STRING_AGG(CONVERT(nvarchar(max), N'd.' + QUOTENAME(dest_column) + N' = s.' + QUOTENAME(source_column)), N',') WITHIN GROUP (ORDER BY ordinal)
            FROM #pair_cols;

            /* La clé métier sert à faire correspondre les lignes entre bases. Les
               colonnes de clé doivent porter le même nom dans les deux tables. */
            SELECT @join_keys = STRING_AGG(CONVERT(nvarchar(max), N'd.' + QUOTENAME(LTRIM(RTRIM(value)))
                                         + N' = s.' + QUOTENAME(LTRIM(RTRIM(value)))), N' AND ')
            FROM STRING_SPLIT(REPLACE(@id_table, N'|', N','), N',')
            WHERE LTRIM(RTRIM(value)) <> N'';
            IF @join_keys IS NULL
            BEGIN
                THROW 51014, 'Cle de correspondance vide dans le mapping.', 1;
            END;

            /* La logique historique sendata Windows -> Web ajoute les champs gérés
               par l'application, sans les lire du mapping : franchise=0 et
               cod_cach='01'. On vérifie chaque destination, y compris les extensions,
               avant de les ajouter à l'INSERT/UPDATE pour éviter les colonnes absentes. */
            SET @dest_has_franchise = 0;
            SET @dest_has_cod_cach = 0;
            SET @sql = N'SELECT @p_has = CASE WHEN EXISTS
                (SELECT 1 FROM ' + QUOTENAME(@db_dest) + N'.sys.tables t
                 JOIN ' + QUOTENAME(@db_dest) + N'.sys.schemas sc ON sc.schema_id=t.schema_id
                 JOIN ' + QUOTENAME(@db_dest) + N'.sys.columns c ON c.object_id=t.object_id
                 WHERE sc.name=N''dbo'' AND t.name=@p_table AND c.name=N''franchise'')
                THEN 1 ELSE 0 END,
                @p_has_cod_cach = CASE WHEN EXISTS
                (SELECT 1 FROM ' + QUOTENAME(@db_dest) + N'.sys.tables t
                 JOIN ' + QUOTENAME(@db_dest) + N'.sys.schemas sc ON sc.schema_id=t.schema_id
                 JOIN ' + QUOTENAME(@db_dest) + N'.sys.columns c ON c.object_id=t.object_id
                 WHERE sc.name=N''dbo'' AND t.name=@p_table AND c.name=N''cod_cach'')
                THEN 1 ELSE 0 END;';
            EXEC sys.sp_executesql @sql,
                N'@p_table sysname,@p_has bit OUTPUT,@p_has_cod_cach bit OUTPUT',
                @p_table = @table_dest,
                @p_has = @dest_has_franchise OUTPUT,
                @p_has_cod_cach = @dest_has_cod_cach OUTPUT;

            SET @insert_cols = @dest_projection;
            IF @source_is_windows = 1 AND @dest_has_franchise = 1
                SET @insert_cols += N',[franchise]';
            IF @source_is_windows = 1 AND @dest_has_cod_cach = 1
                SET @insert_cols += N',[cod_cach]';
            IF @source_is_windows = 1 AND @dest_has_franchise = 1
                SET @update_set += N',d.[franchise] = @p_franchise';
            IF @source_is_windows = 1 AND @dest_has_cod_cach = 1
                SET @update_set += N',d.[cod_cach] = @p_cod_cach';

            /* Désactiver le déclencheur de synchronisation de la cible pour ne pas
               remettre dans la file le changement que sendata2 est en train d'appliquer. */
            SET @sql = N'UPDATE ' + QUOTENAME(@db_dest)
                + N'.dbo.Config_Trigger SET is_active=0 WHERE table_name=@p_table;';
            EXEC sys.sp_executesql @sql, N'@p_table sysname', @p_table = @table_dest;

            IF @OperationType IN ('INSERT','UPDATE')
            BEGIN
                /* UPSERT partiel : mettre à jour les colonnes mappées si la clé existe;
                   sinon insérer la projection. On ne supprime pas la ligne entière,
                   ce qui permet aux tables d'extension de compléter leur parent. */
                PRINT N'INSERT or UPDATE - upsert colonnes mappees';
                SET @sql = N'UPDATE d SET ' + @update_set
                    + N' FROM ' + QUOTENAME(@db_dest) + N'.dbo.' + QUOTENAME(@table_dest) + N' AS d'
                    + N' INNER JOIN ' + QUOTENAME(@db_source) + N'.dbo.' + QUOTENAME(@table_source) + N' AS s ON ' + @join_keys
                    + N' WHERE EXISTS (SELECT 1 FROM #group_recno r WHERE r.recno=s.recno);';
                PRINT @sql;
                EXEC sys.sp_executesql @sql,
                    N'@p_franchise bit,@p_cod_cach varchar(4)',
                    @p_franchise = @franchise, @p_cod_cach = @vcod_cach;

                IF @source_is_windows = 0 AND @NomTable <> @table_dest
                BEGIN
                    /* Une extension Web ne crée jamais un parent Windows manquant.
                       Cette situation est journalisée et le groupe reste en attente. */
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
                        + CASE WHEN @source_is_windows = 1 AND @dest_has_cod_cach = 1 THEN N',@p_cod_cach' ELSE N'' END
                        + N' FROM ' + QUOTENAME(@db_source) + N'.dbo.' + QUOTENAME(@table_source) + N' AS s'
                        + N' WHERE EXISTS (SELECT 1 FROM #group_recno r WHERE r.recno=s.recno)'
                        + N' AND NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@db_dest) + N'.dbo.' + QUOTENAME(@table_dest) + N' AS d WHERE ' + @join_keys + N');';
                    PRINT @sql;
                    EXEC sys.sp_executesql @sql,
                        N'@p_franchise bit,@p_cod_cach varchar(4)',
                        @p_franchise = @franchise, @p_cod_cach = @vcod_cach;
                END;
            END
            ELSE IF @OperationType = 'DELETE'
            BEGIN
                PRINT N'DELETE';
                /* Les num_id du groupe identifient les lignes supprimées. Les valeurs
                   dupliquées sont éliminées avant fn_GenerateWhere2. */
                ;WITH ids_uniques AS
                (
                    SELECT DISTINCT LTRIM(RTRIM(num_id)) AS num_id
                    FROM #work
                    WHERE OperationType = @OperationType AND NomTable = @NomTable
                      AND bd_name = @bd_name AND cod_config = @cod_config
                      AND NULLIF(LTRIM(RTRIM(num_id)), N'') IS NOT NULL
                )
                SELECT @ids = STRING_AGG(CONVERT(nvarchar(max), num_id), N',')
                FROM ids_uniques;
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

                /* Réactiver le déclencheur après la mise à jour de cette destination. */
                PRINT N'----- Fin mapping destination : ' + @table_dest;
            FETCH NEXT FROM map_cursor INTO @table_dest, @cols_source, @cols_dest, @id_table;
        END;

        CLOSE map_cursor;
        DEALLOCATE map_cursor;

        /* Retirer uniquement les événements capturés de ce groupe, et seulement
           après la réussite de toutes les destinations. */
        DELETE h
        FROM dbo.Historique_Transactions AS h
        INNER JOIN #work AS w ON w.HistId = h.HistId
        WHERE w.OperationType = @OperationType AND w.NomTable = @NomTable
          AND w.bd_name = @bd_name AND w.cod_config = @cod_config;

        /* Le succès est inscrit dans la même transaction que la réplication :
           le code 200 n'est conservé que si les changements et le COMMIT réussissent. */
        INSERT dbo.p00004030(code_err, lib_err, franchise, date_err, heure_err)
        VALUES (200, CONCAT(@NomTable, N' terminée avec succès'), @franchise,
                GETDATE(), CONVERT(time, GETDATE()));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        /* En cas d'erreur, restaurer la transaction complète, conserver les événements
           non traités dans l'historique, enregistrer le diagnostic et afficher le SQL. */
        IF CURSOR_STATUS('local', 'map_cursor') >= 0 CLOSE map_cursor;
        IF CURSOR_STATUS('local', 'map_cursor') >= -1 DEALLOCATE map_cursor;
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        INSERT dbo.p00004030(code_err, lib_err, franchise, date_err, heure_err)
        VALUES (ERROR_NUMBER(), CONCAT(@NomTable, N' : ', ERROR_MESSAGE()), @franchise,
                GETDATE(), CONVERT(time, GETDATE()));
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
