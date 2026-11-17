USE [BaseInterconnexion];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_GenerateWhere2
(
    @id_table  nvarchar(max), -- ex. nofact,nocamp,cod_sit,franchise,cod_pays
    @values_id nvarchar(max)  -- ex. 26A885|2027|01|0|225,autre clé composée...
)
RETURNS nvarchar(max)
AS
BEGIN
    DECLARE @where nvarchar(max), @columns nvarchar(max);

    IF NULLIF(LTRIM(RTRIM(@id_table)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@values_id)), N'') IS NULL
        RETURN N'';

    /* Les mappings historiques utilisent des virgules; accepter aussi |. */
    SET @columns = REPLACE(@id_table, N'|', N',');

    ;WITH Colonnes AS
    (
        SELECT ordinal AS position,
               LTRIM(RTRIM(value)) AS colonne
        FROM STRING_SPLIT(@columns, N',', 1)
        WHERE LTRIM(RTRIM(value)) <> N''
    ),
    ValeursBrutes AS
    (
        SELECT ordinal AS position_ligne,
               LTRIM(RTRIM(value)) AS valeur_composee
        FROM STRING_SPLIT(@values_id, N',', 1)
        WHERE LTRIM(RTRIM(value)) <> N''
    ),
    Valeurs AS
    (
        SELECT v.position_ligne,
               s.ordinal AS position_colonne,
               LTRIM(RTRIM(s.value)) AS valeur
        FROM ValeursBrutes AS v
        CROSS APPLY STRING_SPLIT(v.valeur_composee, N'|', 1) AS s
    ),
    NbColonnes AS
    (
        SELECT COUNT(*) AS nombre FROM Colonnes
    ),
    LignesValides AS
    (
        /* Une clé composée doit fournir exactement une valeur par colonne. */
        SELECT v.position_ligne
        FROM Valeurs AS v
        CROSS JOIN NbColonnes AS n
        GROUP BY v.position_ligne, n.nombre
        HAVING COUNT(*) = n.nombre
           AND MIN(v.position_colonne) = 1
           AND MAX(v.position_colonne) = n.nombre
    ),
    Conditions AS
    (
        SELECT v.position_ligne,
               STRING_AGG
               (
                   CONVERT(nvarchar(max), QUOTENAME(c.colonne) + N' = N''' + REPLACE(v.valeur, N'''', N'''''') + N''''),
                   N' AND '
               ) WITHIN GROUP (ORDER BY c.position) AS condition_ligne
        FROM Valeurs AS v
        INNER JOIN Colonnes AS c ON c.position = v.position_colonne
        INNER JOIN LignesValides AS lv ON lv.position_ligne = v.position_ligne
        GROUP BY v.position_ligne
    )
    SELECT @where = STRING_AGG
    (
        CONVERT(nvarchar(max), N'(' + condition_ligne + N')'),
        N' OR '
    ) WITHIN GROUP (ORDER BY position_ligne)
    FROM Conditions;

    RETURN ISNULL(@where, N'');
END;
GO

/* Vérification facultative :
SELECT dbo.fn_GenerateWhere(
    N'nofact,nocamp,cod_sit,franchise,cod_pays',
    N'26A885|2027|01|0|225'
);
-- Produit : ([nofact] = N'26A885' AND [nocamp] = N'2027' AND
--            [cod_sit] = N'01' AND [franchise] = N'0' AND [cod_pays] = N'225')
*/
