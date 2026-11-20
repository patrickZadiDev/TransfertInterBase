/*
    Harmonisation des types de colonnes entre les tables Windows et Web.

    Le script est un GENERATEUR : il ne lance aucun ALTER TABLE.
    Il retourne deux jeux de résultats :
      1. les commandes ALTER COLUMN à relire puis exécuter séparément;
      2. les anomalies nécessitant une décision (table/colonne absente,
         familles incompatibles, identité, nullabilité différente, etc.).

    Compatibilités prises en charge :
      - char/varchar/nchar/nvarchar/text/ntext -> varchar(n ou max);
      - decimal/numeric et entiers/money -> numeric(p,s), avec capacité commune
        calculée à partir des chiffres entiers et de l'échelle des deux côtés.
      - types différents d'une famille ne sont pas convertis automatiquement.

    Les listes col_window et col_web de mapping_windows_web sont considérées
    comme alignées par position et séparées par des virgules. Les colonnes de
    même nom sont aussi comparées automatiquement, même si elles ne figurent
    pas dans ces listes. recno identity est signalé et jamais modifié.

    Pré-requis : exécuter dans BaseInterconnexion. STRING_SPLIT(..., 1) requiert
    SQL Server 2022 (ou une version compatible avec l'ordinal de STRING_SPLIT).
*/
USE [BaseInterconnexion];
GO
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#SchemaColumns') IS NOT NULL DROP TABLE #SchemaColumns;
IF OBJECT_ID('tempdb..#AllSchemaColumns') IS NOT NULL DROP TABLE #AllSchemaColumns;
IF OBJECT_ID('tempdb..#ColumnPairs') IS NOT NULL DROP TABLE #ColumnPairs;
IF OBJECT_ID('tempdb..#AlterScripts') IS NOT NULL DROP TABLE #AlterScripts;
IF OBJECT_ID('tempdb..#SchemaIssues') IS NOT NULL DROP TABLE #SchemaIssues;

CREATE TABLE #SchemaColumns
(
    SideCode char(1) NOT NULL,
    DatabaseName sysname NOT NULL,
    TableName sysname NOT NULL,
    ColumnName sysname NOT NULL,
    BaseType sysname NOT NULL,
    MaxLength smallint NOT NULL,
    [Precision] tinyint NOT NULL,
    ScaleValue tinyint NOT NULL,
    IsNullable bit NOT NULL,
    IsIdentity bit NOT NULL,
    DefaultConstraintName sysname NULL,
    DefaultDefinition nvarchar(max) NULL
);

CREATE TABLE #ColumnPairs
(
    WindowColumn sysname NOT NULL,
    WebColumn sysname NOT NULL
);

CREATE TABLE #AllSchemaColumns
(
    SideCode char(1) NOT NULL,
    DatabaseName sysname NOT NULL,
    TableName sysname NOT NULL,
    ColumnName sysname NOT NULL,
    ExistingType nvarchar(100) NULL
);

CREATE TABLE #AlterScripts
(
    ScriptId int IDENTITY(1,1) NOT NULL,
    ConfigCode varchar(10) NULL,
    DatabaseName sysname NOT NULL,
    TableName sysname NOT NULL,
    ColumnName sysname NOT NULL,
    typ_windows nvarchar(100) NULL,
    type_web nvarchar(100) NULL,
    ProposedType nvarchar(100) NOT NULL,
    ScriptDropDefault nvarchar(max) NULL,
    ScriptAddDefault nvarchar(max) NULL,
    ScriptText nvarchar(max) NOT NULL
);

CREATE TABLE #SchemaIssues
(
    IssueId int IDENTITY(1,1) NOT NULL,
    ConfigCode varchar(10) NULL,
    WindowDatabase sysname NULL,
    WindowTable sysname NULL,
    WindowColumn sysname NULL,
    WebDatabase sysname NULL,
    WebTable sysname NULL,
    WebColumn sysname NULL,
    typ_windows nvarchar(100) NULL,
    type_web nvarchar(100) NULL,
    Issue nvarchar(2000) NOT NULL
);

DECLARE
    @ConfigCode varchar(10), @WindowDatabase sysname, @WebDatabase sysname,
    @WindowTable sysname, @WebTable sysname,
    @WindowColumnList nvarchar(max), @WebColumnList nvarchar(max),
    @WindowColumn sysname, @WebColumn sysname,
    @WindowType sysname, @WebType sysname,
    @WindowLength smallint, @WebLength smallint,
    @WindowPrecision tinyint, @WebPrecision tinyint,
    @WindowScale tinyint, @WebScale tinyint,
    @WindowNullable bit, @WebNullable bit,
    @WindowIdentity bit, @WebIdentity bit,
    @WindowExistingType nvarchar(100), @WebExistingType nvarchar(100),
    @WindowDefaultName sysname, @WebDefaultName sysname,
    @WindowDefaultDefinition nvarchar(max), @WebDefaultDefinition nvarchar(max),
    @WindowChars int, @WebChars int, @CommonLength int,
    @WindowIntegerDigits int, @WebIntegerDigits int,
    @CommonIntegerDigits int, @CommonScale int, @CommonPrecision int,
    @CommonType nvarchar(100), @Side char(1), @DatabaseName sysname,
    @TableName sysname, @Sql nvarchar(max), @ColumnCursorStatus int;

DECLARE table_pairs CURSOR LOCAL FAST_FORWARD FOR
    SELECT DISTINCT
        CONVERT(varchar(10), m.config_base),
        NULLIF(LTRIM(RTRIM(cfg.db_source)), N''),
        NULLIF(LTRIM(RTRIM(cfg.db_dest)), N''),
        NULLIF(LTRIM(RTRIM(m.tab_window)), N''),
        NULLIF(LTRIM(RTRIM(m.tab_web)), N''),
        CONVERT(nvarchar(max), m.col_window),
        CONVERT(nvarchar(max), m.col_web)
    FROM dbo.mapping_windows_web AS m
    INNER JOIN dbo.wconfig_base() AS cfg
        ON cfg.cod_config = m.config_base
    WHERE NULLIF(LTRIM(RTRIM(cfg.db_source)), N'') IS NOT NULL
      AND NULLIF(LTRIM(RTRIM(cfg.db_dest)), N'') IS NOT NULL
      AND NULLIF(LTRIM(RTRIM(m.tab_window)), N'') IS NOT NULL
      AND NULLIF(LTRIM(RTRIM(m.tab_web)), N'') IS NOT NULL
	  and cfg.cod_config = '11'

OPEN table_pairs;
FETCH NEXT FROM table_pairs INTO
    @ConfigCode, @WindowDatabase, @WebDatabase, @WindowTable, @WebTable,
    @WindowColumnList, @WebColumnList;

WHILE @@FETCH_STATUS = 0
BEGIN
    DELETE FROM #SchemaColumns;
    DELETE FROM #ColumnPairs;

    /* Charger les métadonnées sans exécuter de DDL dans les bases applicatives. */
    SET @Side = 'W'; SET @DatabaseName = @WindowDatabase; SET @TableName = @WindowTable;
    SET @Sql = N'
        INSERT #SchemaColumns
            (SideCode, DatabaseName, TableName, ColumnName, BaseType, MaxLength,
             [Precision], ScaleValue, IsNullable, IsIdentity,
             DefaultConstraintName, DefaultDefinition)
        SELECT @p_side, @p_db, t.name, c.name, bt.name, c.max_length,
               c.[precision], c.scale, c.is_nullable, c.is_identity,
               dc.name, dc.definition
        FROM ' + QUOTENAME(@DatabaseName) + N'.sys.tables AS t
        INNER JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.schemas AS s ON s.schema_id = t.schema_id
        INNER JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.columns AS c ON c.object_id = t.object_id
        INNER JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.types AS bt
            ON bt.user_type_id = c.system_type_id AND bt.is_user_defined = 0
        LEFT JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.default_constraints AS dc
            ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE s.name = N''dbo'' AND t.name = @p_table;';
    EXEC sys.sp_executesql @Sql, N'@p_side char(1),@p_db sysname,@p_table sysname',
        @p_side = @Side, @p_db = @DatabaseName, @p_table = @TableName;

    INSERT #AllSchemaColumns(SideCode, DatabaseName, TableName, ColumnName, ExistingType)
    SELECT SideCode, DatabaseName, TableName, ColumnName,
           CASE
               WHEN BaseType IN (N'text',N'ntext') THEN BaseType
               WHEN BaseType IN (N'decimal',N'numeric')
                   THEN BaseType + N'(' + CONVERT(nvarchar(10), [Precision]) + N',' + CONVERT(nvarchar(10), ScaleValue) + N')'
               WHEN BaseType IN (N'char',N'varchar',N'nchar',N'nvarchar')
                   THEN BaseType + N'(' + CASE WHEN MaxLength = -1 THEN N'max'
                        WHEN BaseType IN (N'nchar',N'nvarchar') THEN CONVERT(nvarchar(10), MaxLength / 2)
                        ELSE CONVERT(nvarchar(10), MaxLength) END + N')'
               ELSE BaseType
           END
    FROM #SchemaColumns;

    SET @Side = 'B'; SET @DatabaseName = @WebDatabase; SET @TableName = @WebTable;
    SET @Sql = N'
        INSERT #SchemaColumns
            (SideCode, DatabaseName, TableName, ColumnName, BaseType, MaxLength,
             [Precision], ScaleValue, IsNullable, IsIdentity,
             DefaultConstraintName, DefaultDefinition)
        SELECT @p_side, @p_db, t.name, c.name, bt.name, c.max_length,
               c.[precision], c.scale, c.is_nullable, c.is_identity,
               dc.name, dc.definition
        FROM ' + QUOTENAME(@DatabaseName) + N'.sys.tables AS t
        INNER JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.schemas AS s ON s.schema_id = t.schema_id
        INNER JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.columns AS c ON c.object_id = t.object_id
        INNER JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.types AS bt
            ON bt.user_type_id = c.system_type_id AND bt.is_user_defined = 0
        LEFT JOIN ' + QUOTENAME(@DatabaseName) + N'.sys.default_constraints AS dc
            ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
        WHERE s.name = N''dbo'' AND t.name = @p_table;';
    EXEC sys.sp_executesql @Sql, N'@p_side char(1),@p_db sysname,@p_table sysname',
        @p_side = @Side, @p_db = @DatabaseName, @p_table = @TableName;

    INSERT #AllSchemaColumns(SideCode, DatabaseName, TableName, ColumnName, ExistingType)
    SELECT SideCode, DatabaseName, TableName, ColumnName,
           CASE
               WHEN BaseType IN (N'text',N'ntext') THEN BaseType
               WHEN BaseType IN (N'decimal',N'numeric')
                   THEN BaseType + N'(' + CONVERT(nvarchar(10), [Precision]) + N',' + CONVERT(nvarchar(10), ScaleValue) + N')'
               WHEN BaseType IN (N'char',N'varchar',N'nchar',N'nvarchar')
                   THEN BaseType + N'(' + CASE WHEN MaxLength = -1 THEN N'max'
                        WHEN BaseType IN (N'nchar',N'nvarchar') THEN CONVERT(nvarchar(10), MaxLength / 2)
                        ELSE CONVERT(nvarchar(10), MaxLength) END + N')'
               ELSE BaseType
           END
    FROM #SchemaColumns
    WHERE SideCode = 'B';

    IF NOT EXISTS (SELECT 1 FROM #SchemaColumns WHERE SideCode = 'W')
       OR NOT EXISTS (SELECT 1 FROM #SchemaColumns WHERE SideCode = 'B')
    BEGIN
        INSERT #SchemaIssues
            (ConfigCode, WindowDatabase, WindowTable, WebDatabase, WebTable, Issue)
        VALUES
            (@ConfigCode, @WindowDatabase, @WindowTable, @WebDatabase, @WebTable,
             CASE
                 WHEN NOT EXISTS (SELECT 1 FROM #SchemaColumns WHERE SideCode = 'W')
                  AND NOT EXISTS (SELECT 1 FROM #SchemaColumns WHERE SideCode = 'B')
                     THEN N'Les deux tables sont introuvables dans le schéma dbo.'
                 WHEN NOT EXISTS (SELECT 1 FROM #SchemaColumns WHERE SideCode = 'W')
                     THEN N'Table Windows introuvable dans le schéma dbo.'
                 ELSE N'Table Web introuvable dans le schéma dbo.'
             END);
        GOTO NextTablePair;
    END;

    /* Les listes du mapping donnent les paires de colonnes, même si leurs noms diffèrent. */
    IF NULLIF(LTRIM(RTRIM(@WindowColumnList)), N'') IS NOT NULL
       AND NULLIF(LTRIM(RTRIM(@WebColumnList)), N'') IS NOT NULL
    BEGIN
        INSERT #ColumnPairs(WindowColumn, WebColumn)
        SELECT DISTINCT LTRIM(RTRIM(w.value)), LTRIM(RTRIM(b.value))
        FROM STRING_SPLIT(@WindowColumnList, N',', 1) AS w
        INNER JOIN STRING_SPLIT(@WebColumnList, N',', 1) AS b
            ON b.ordinal = w.ordinal
        WHERE LTRIM(RTRIM(w.value)) <> N''
          AND LTRIM(RTRIM(b.value)) <> N''
          AND LOWER(LTRIM(RTRIM(w.value))) <> N'recno'
          AND LOWER(LTRIM(RTRIM(b.value))) <> N'recno';

        /* Signaler les listes dont les éléments ne sont pas appariés par position. */
        IF (SELECT COUNT(*) FROM STRING_SPLIT(@WindowColumnList, N',', 1))
           <> (SELECT COUNT(*) FROM STRING_SPLIT(@WebColumnList, N',', 1))
            INSERT #SchemaIssues
                (ConfigCode, WindowDatabase, WindowTable, WebDatabase, WebTable, Issue)
            VALUES (@ConfigCode, @WindowDatabase, @WindowTable, @WebDatabase, @WebTable,
                    N'Les listes col_window et col_web n''ont pas le même nombre d''éléments; seules les positions appariées seront comparées.');
    END;

    /* Compléter avec toutes les colonnes de même nom présentes des deux côtés. */
    INSERT #ColumnPairs(WindowColumn, WebColumn)
    SELECT w.ColumnName, b.ColumnName
    FROM #SchemaColumns AS w
    INNER JOIN #SchemaColumns AS b
        ON b.SideCode = 'B' AND b.ColumnName = w.ColumnName
    WHERE w.SideCode = 'W'
      AND LOWER(w.ColumnName) <> N'recno'
      AND NOT EXISTS
          (SELECT 1 FROM #ColumnPairs AS p
           WHERE p.WindowColumn = w.ColumnName AND p.WebColumn = b.ColumnName);

    DECLARE column_pairs CURSOR LOCAL FAST_FORWARD FOR
        SELECT WindowColumn, WebColumn FROM #ColumnPairs;
    OPEN column_pairs;
    FETCH NEXT FROM column_pairs INTO @WindowColumn, @WebColumn;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @WindowDefaultName = NULL;
        SET @WebDefaultName = NULL;
        SET @WindowDefaultDefinition = NULL;
        SET @WebDefaultDefinition = NULL;

        SELECT @WindowType = BaseType, @WindowLength = MaxLength,
               @WindowPrecision = [Precision], @WindowScale = ScaleValue,
               @WindowNullable = IsNullable, @WindowIdentity = IsIdentity,
               @WindowDefaultName = DefaultConstraintName,
               @WindowDefaultDefinition = DefaultDefinition
        FROM #SchemaColumns WHERE SideCode = 'W' AND ColumnName = @WindowColumn;
        SELECT @WebType = BaseType, @WebLength = MaxLength,
               @WebPrecision = [Precision], @WebScale = ScaleValue,
               @WebNullable = IsNullable, @WebIdentity = IsIdentity,
               @WebDefaultName = DefaultConstraintName,
               @WebDefaultDefinition = DefaultDefinition
        FROM #SchemaColumns WHERE SideCode = 'B' AND ColumnName = @WebColumn;

        SET @WindowExistingType = CASE
            WHEN @WindowType IN (N'text',N'ntext') THEN @WindowType
            WHEN @WindowType IN (N'decimal',N'numeric')
                THEN @WindowType + N'(' + CONVERT(nvarchar(10), @WindowPrecision) + N',' + CONVERT(nvarchar(10), @WindowScale) + N')'
            WHEN @WindowType IN (N'char',N'varchar',N'nchar',N'nvarchar')
                THEN @WindowType + N'(' + CASE WHEN @WindowLength = -1 THEN N'max'
                     WHEN @WindowType IN (N'nchar',N'nvarchar') THEN CONVERT(nvarchar(10), @WindowLength / 2)
                     ELSE CONVERT(nvarchar(10), @WindowLength) END + N')'
            ELSE @WindowType END;
        SET @WebExistingType = CASE
            WHEN @WebType IN (N'text',N'ntext') THEN @WebType
            WHEN @WebType IN (N'decimal',N'numeric')
                THEN @WebType + N'(' + CONVERT(nvarchar(10), @WebPrecision) + N',' + CONVERT(nvarchar(10), @WebScale) + N')'
            WHEN @WebType IN (N'char',N'varchar',N'nchar',N'nvarchar')
                THEN @WebType + N'(' + CASE WHEN @WebLength = -1 THEN N'max'
                     WHEN @WebType IN (N'nchar',N'nvarchar') THEN CONVERT(nvarchar(10), @WebLength / 2)
                     ELSE CONVERT(nvarchar(10), @WebLength) END + N')'
            ELSE @WebType END;

        IF @WindowType IS NULL OR @WebType IS NULL
        BEGIN
            INSERT #SchemaIssues
                (ConfigCode, WindowDatabase, WindowTable, WindowColumn,
                 WebDatabase, WebTable, WebColumn, Issue)
            VALUES
                (@ConfigCode, @WindowDatabase, @WindowTable, @WindowColumn,
                 @WebDatabase, @WebTable, @WebColumn,
                 CASE WHEN @WindowType IS NULL
                      THEN N'Colonne Windows absente.'
                      ELSE N'Colonne Web absente.' END);
        END
        ELSE
        BEGIN
            SET @CommonType = NULL;
            SET @CommonLength = NULL;

            IF @WindowType IN (N'char',N'varchar',N'nchar',N'nvarchar',N'text',N'ntext')
               AND @WebType IN (N'char',N'varchar',N'nchar',N'nvarchar',N'text',N'ntext')
            BEGIN
                SET @WindowChars = CASE WHEN @WindowType IN (N'nchar',N'nvarchar') AND @WindowLength > 0
                                        THEN @WindowLength / 2 ELSE @WindowLength END;
                SET @WebChars = CASE WHEN @WebType IN (N'nchar',N'nvarchar') AND @WebLength > 0
                                     THEN @WebLength / 2 ELSE @WebLength END;
                IF @WindowLength = -1 OR @WebLength = -1
                   OR @WindowType IN (N'text',N'ntext') OR @WebType IN (N'text',N'ntext')
                    SET @CommonType = N'varchar(max)';
                ELSE
                BEGIN
                    SET @CommonLength = CASE WHEN @WindowChars > @WebChars THEN @WindowChars ELSE @WebChars END;
                    IF @CommonLength > 8000 SET @CommonType = N'varchar(max)';
                    ELSE SET @CommonType = N'varchar(' + CONVERT(nvarchar(10), @CommonLength) + N')';
                END;
            END
            ELSE IF @WindowType IN (N'decimal',N'numeric',N'tinyint',N'smallint',N'int',N'bigint',N'money',N'smallmoney')
                AND @WebType IN (N'decimal',N'numeric',N'tinyint',N'smallint',N'int',N'bigint',N'money',N'smallmoney')
            BEGIN
                IF @WindowType = @WebType AND @WindowType NOT IN (N'decimal',N'numeric')
                    SET @CommonType = NULL;
                ELSE
                BEGIN
                SET @WindowIntegerDigits = CASE
                    WHEN @WindowType IN (N'decimal',N'numeric') THEN @WindowPrecision - @WindowScale
                    WHEN @WindowType = N'tinyint' THEN 3
                    WHEN @WindowType = N'smallint' THEN 5
                    WHEN @WindowType = N'int' THEN 10
                    WHEN @WindowType = N'bigint' THEN 19
                    WHEN @WindowType = N'money' THEN 15
                    WHEN @WindowType = N'smallmoney' THEN 6 END;
                SET @WebIntegerDigits = CASE
                    WHEN @WebType IN (N'decimal',N'numeric') THEN @WebPrecision - @WebScale
                    WHEN @WebType = N'tinyint' THEN 3
                    WHEN @WebType = N'smallint' THEN 5
                    WHEN @WebType = N'int' THEN 10
                    WHEN @WebType = N'bigint' THEN 19
                    WHEN @WebType = N'money' THEN 15
                    WHEN @WebType = N'smallmoney' THEN 6 END;
                SET @CommonIntegerDigits = CASE WHEN @WindowIntegerDigits > @WebIntegerDigits
                                                 THEN @WindowIntegerDigits ELSE @WebIntegerDigits END;
                SET @CommonScale = CASE WHEN @WindowScale > @WebScale THEN @WindowScale ELSE @WebScale END;
                SET @CommonPrecision = @CommonIntegerDigits + @CommonScale;

                IF @CommonPrecision <= 38
                    SET @CommonType = N'numeric(' + CONVERT(nvarchar(10), @CommonPrecision)
                                    + N',' + CONVERT(nvarchar(10), @CommonScale) + N')';
                ELSE
                    INSERT #SchemaIssues
                        (ConfigCode, WindowDatabase, WindowTable, WindowColumn,
                         WebDatabase, WebTable, WebColumn, Issue)
                    VALUES
                        (@ConfigCode, @WindowDatabase, @WindowTable, @WindowColumn,
                         @WebDatabase, @WebTable, @WebColumn,
                         N'La capacité numérique commune dépasse la précision maximale 38; aucune commande ALTER générée.');
                END;
            END
            ELSE IF @WindowType <> @WebType
            BEGIN
                INSERT #SchemaIssues
                    (ConfigCode, WindowDatabase, WindowTable, WindowColumn,
                     WebDatabase, WebTable, WebColumn, Issue)
                VALUES
                    (@ConfigCode, @WindowDatabase, @WindowTable, @WindowColumn,
                     @WebDatabase, @WebTable, @WebColumn,
                     N'Types incompatibles: ' + @WindowType + N' et ' + @WebType
                     + N'. Aucune commande ALTER générée; choix manuel requis.');
            END;

            IF @CommonType IS NOT NULL
            BEGIN
                /* Ne pas tenter de modifier la propriété identity. */
                IF @WindowIdentity = 1 OR @WebIdentity = 1
                BEGIN
                    INSERT #SchemaIssues
                        (ConfigCode, WindowDatabase, WindowTable, WindowColumn,
                         WebDatabase, WebTable, WebColumn, Issue)
                    VALUES
                        (@ConfigCode, @WindowDatabase, @WindowTable, @WindowColumn,
                         @WebDatabase, @WebTable, @WebColumn,
                         N'Une colonne identity requiert une vérification manuelle; les ALTER ne sont pas générés pour cette paire.');
                END
                ELSE
                BEGIN
                    IF @WindowType IN (N'nchar',N'nvarchar',N'ntext')
                       OR @WebType IN (N'nchar',N'nvarchar',N'ntext')
                        INSERT #SchemaIssues
                            (ConfigCode, WindowDatabase, WindowTable, WindowColumn,
                             WebDatabase, WebTable, WebColumn, Issue)
                        VALUES
                            (@ConfigCode, @WindowDatabase, @WindowTable, @WindowColumn,
                             @WebDatabase, @WebTable, @WebColumn,
                             N'La conversion Unicode vers varchar peut perdre des caractères non représentables par la page de codes de destination; vérifier les données avant exécution.');

                    IF NOT (@WindowType = N'varchar' AND
                            ((@CommonType = N'varchar(max)' AND @WindowLength = -1) OR
                             (@CommonType <> N'varchar(max)' AND @WindowLength = @CommonLength)))
                       AND NOT (@WindowType = N'numeric'
                                AND @WindowPrecision = @CommonPrecision AND @WindowScale = @CommonScale)
                    BEGIN
                        INSERT #AlterScripts
                            (ConfigCode, DatabaseName, TableName, ColumnName, typ_windows, type_web,
                             ProposedType, ScriptDropDefault, ScriptAddDefault, ScriptText)
                        VALUES
                            (@ConfigCode, @WindowDatabase, @WindowTable, @WindowColumn, @WindowExistingType, @WebExistingType,
                             @CommonType,
                             CASE WHEN @WindowDefaultName IS NULL THEN NULL
                                  ELSE N'IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@WindowDatabase)
                                       + N'.sys.default_constraints WHERE name = N'''
                                       + REPLACE(@WindowDefaultName, N'''', N'''''')
                                       + N''' AND parent_object_id = OBJECT_ID(N'''
                                       + REPLACE(QUOTENAME(@WindowDatabase) + N'.dbo.' + QUOTENAME(@WindowTable), N'''', N'''''')
                                       + N''')) BEGIN ALTER TABLE ' + QUOTENAME(@WindowDatabase) + N'.dbo.' + QUOTENAME(@WindowTable)
                                       + N' DROP CONSTRAINT ' + QUOTENAME(@WindowDefaultName) + N'; END;' END,
                             CASE WHEN @WindowDefaultName IS NULL THEN NULL
                                  ELSE N'IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@WindowDatabase)
                                       + N'.sys.default_constraints WHERE name = N'''
                                       + REPLACE(@WindowDefaultName, N'''', N'''''')
                                       + N''' AND parent_object_id = OBJECT_ID(N'''
                                       + REPLACE(QUOTENAME(@WindowDatabase) + N'.dbo.' + QUOTENAME(@WindowTable), N'''', N'''''')
                                       + N''')) BEGIN ALTER TABLE ' + QUOTENAME(@WindowDatabase) + N'.dbo.' + QUOTENAME(@WindowTable)
                                       + N' ADD CONSTRAINT ' + QUOTENAME(@WindowDefaultName)
                                       + N' DEFAULT ' + @WindowDefaultDefinition + N' FOR ' + QUOTENAME(@WindowColumn) + N'; END;' END,
                             N'BEGIN TRY ALTER TABLE ' + QUOTENAME(@WindowDatabase) + N'.dbo.' + QUOTENAME(@WindowTable)
                             + N' ALTER COLUMN ' + QUOTENAME(@WindowColumn) + N' ' + @CommonType
                             + CASE WHEN @WindowNullable = 1 THEN N' NULL;' ELSE N' NOT NULL;' END
                             + N' END TRY BEGIN CATCH PRINT N''Erreur ALTER COLUMN Windows : '' + ERROR_MESSAGE(); END CATCH;');
                    END;

                    IF NOT (@WebType = N'varchar' AND
                            ((@CommonType = N'varchar(max)' AND @WebLength = -1) OR
                             (@CommonType <> N'varchar(max)' AND @WebLength = @CommonLength)))
                       AND NOT (@WebType = N'numeric'
                                AND @WebPrecision = @CommonPrecision AND @WebScale = @CommonScale)
                    BEGIN
                        INSERT #AlterScripts
                            (ConfigCode, DatabaseName, TableName, ColumnName, typ_windows, type_web,
                             ProposedType, ScriptDropDefault, ScriptAddDefault, ScriptText)
                        VALUES
                            (@ConfigCode, @WebDatabase, @WebTable, @WebColumn, @WindowExistingType, @WebExistingType,
                             @CommonType,
                             CASE WHEN @WebDefaultName IS NULL THEN NULL
                                  ELSE N'IF EXISTS (SELECT 1 FROM ' + QUOTENAME(@WebDatabase)
                                       + N'.sys.default_constraints WHERE name = N'''
                                       + REPLACE(@WebDefaultName, N'''', N'''''')
                                       + N''' AND parent_object_id = OBJECT_ID(N'''
                                       + REPLACE(QUOTENAME(@WebDatabase) + N'.dbo.' + QUOTENAME(@WebTable), N'''', N'''''')
                                       + N''')) BEGIN ALTER TABLE ' + QUOTENAME(@WebDatabase) + N'.dbo.' + QUOTENAME(@WebTable)
                                       + N' DROP CONSTRAINT ' + QUOTENAME(@WebDefaultName) + N'; END;' END,
                             CASE WHEN @WebDefaultName IS NULL THEN NULL
                                  ELSE N'IF NOT EXISTS (SELECT 1 FROM ' + QUOTENAME(@WebDatabase)
                                       + N'.sys.default_constraints WHERE name = N'''
                                       + REPLACE(@WebDefaultName, N'''', N'''''')
                                       + N''' AND parent_object_id = OBJECT_ID(N'''
                                       + REPLACE(QUOTENAME(@WebDatabase) + N'.dbo.' + QUOTENAME(@WebTable), N'''', N'''''')
                                       + N''')) BEGIN ALTER TABLE ' + QUOTENAME(@WebDatabase) + N'.dbo.' + QUOTENAME(@WebTable)
                                       + N' ADD CONSTRAINT ' + QUOTENAME(@WebDefaultName)
                                       + N' DEFAULT ' + @WebDefaultDefinition + N' FOR ' + QUOTENAME(@WebColumn) + N'; END;' END,
                             N'BEGIN TRY ALTER TABLE ' + QUOTENAME(@WebDatabase) + N'.dbo.' + QUOTENAME(@WebTable)
                             + N' ALTER COLUMN ' + QUOTENAME(@WebColumn) + N' ' + @CommonType
                             + CASE WHEN @WebNullable = 1 THEN N' NULL;' ELSE N' NOT NULL;' END
                             + N' END TRY BEGIN CATCH PRINT N''Erreur ALTER COLUMN Web : '' + ERROR_MESSAGE(); END CATCH;');
                    END;
                END;
            END;

            IF @WindowNullable <> @WebNullable
                INSERT #SchemaIssues
                    (ConfigCode, WindowDatabase, WindowTable, WindowColumn,
                     WebDatabase, WebTable, WebColumn, Issue)
                VALUES
                    (@ConfigCode, @WindowDatabase, @WindowTable, @WindowColumn,
                     @WebDatabase, @WebTable, @WebColumn,
                     N'La nullabilité diffère entre les tables; elle est conservée dans chaque ALTER, à harmoniser séparément si nécessaire.');
        END;

        SET @WindowType = NULL; SET @WebType = NULL;
        FETCH NEXT FROM column_pairs INTO @WindowColumn, @WebColumn;
    END;

    CLOSE column_pairs;
    DEALLOCATE column_pairs;

    NextTablePair:
    FETCH NEXT FROM table_pairs INTO
        @ConfigCode, @WindowDatabase, @WebDatabase, @WindowTable, @WebTable,
        @WindowColumnList, @WebColumnList;
END;

CLOSE table_pairs;
DEALLOCATE table_pairs;

SELECT ScriptId, ConfigCode, DatabaseName, TableName, ColumnName,
       typ_windows, type_web, ProposedType, ScriptDropDefault, ScriptText, ScriptAddDefault
FROM #AlterScripts
ORDER BY ConfigCode, TableName, ColumnName, DatabaseName;

UPDATE i
SET typ_windows = w.ExistingType,
    type_web = b.ExistingType
FROM #SchemaIssues AS i
OUTER APPLY
(
    SELECT TOP (1) a.ExistingType
    FROM #AllSchemaColumns AS a
    WHERE a.SideCode = 'W' AND a.DatabaseName = i.WindowDatabase
      AND a.TableName = i.WindowTable AND a.ColumnName = i.WindowColumn
) AS w
OUTER APPLY
(
    SELECT TOP (1) a.ExistingType
    FROM #AllSchemaColumns AS a
    WHERE a.SideCode = 'B' AND a.DatabaseName = i.WebDatabase
      AND a.TableName = i.WebTable AND a.ColumnName = i.WebColumn
) AS b;

/* Réafficher les anomalies avec les types renseignés. */
SELECT IssueId, ConfigCode, WindowDatabase, WindowTable, WindowColumn,
       WebDatabase, WebTable, WebColumn, typ_windows, type_web, Issue
FROM #SchemaIssues where typ_windows <> type_web
ORDER BY ConfigCode, WindowTable, WindowColumn, IssueId;

DROP TABLE #ColumnPairs;
DROP TABLE #SchemaColumns;
DROP TABLE #AllSchemaColumns;
DROP TABLE #AlterScripts;
DROP TABLE #SchemaIssues;
GO
