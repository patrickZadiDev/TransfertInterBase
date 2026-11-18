-- ALTER COLUMN generes depuis colonne_diff.xlsx, colonne garder.
-- Ces commandes s executent successivement sur les deux bases de chaque correspondance.
-- Les types varbinary sans longueur dans Excel sont traduits en varbinary(max).
-- Les ALTER sont generes avec NULL, comme dans le modele demande.
-- A relire avant execution. Aucune commande n a ete executee par ce generateur.
-- 101 colonnes retenues; 202 commandes ALTER.
 
-- b00000240.nodem_den | type retenu: char(20) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00000240] ALTER COLUMN [nodem_den] char(20) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00000240] ALTER COLUMN [nodem_den] char(20) NULL;
 
-- b00000940.lib_statut | type retenu: char(60) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00000940] ALTER COLUMN [lib_statut] char(60) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00000940] ALTER COLUMN [lib_statut] char(60) NULL;
 
-- b00000980.cod_per | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00000980] ALTER COLUMN [cod_per] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00000980] ALTER COLUMN [cod_per] char(4) NULL;
 
-- b00001150.cod_dev | type retenu: varchar(5) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00001150] ALTER COLUMN [cod_dev] varchar(5) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00001150] ALTER COLUMN [cod_dev] varchar(5) NULL;
 
-- b00001160.lib_fin | type retenu: char(100) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00001160] ALTER COLUMN [lib_fin] char(100) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00001160] ALTER COLUMN [lib_fin] char(100) NULL;
 
-- b00001200.nobl_vt | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00001200] ALTER COLUMN [nobl_vt] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00001200] ALTER COLUMN [nobl_vt] char(30) NULL;
 
-- b00001250.tare_hous | type retenu: numeric(9,3) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00001250] ALTER COLUMN [tare_hous] numeric(9,3) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00001250] ALTER COLUMN [tare_hous] numeric(9,3) NULL;
 
-- b00002060.DATEMB | type retenu: datetime | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00002060] ALTER COLUMN [datemb] datetime NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00002060] ALTER COLUMN [DATEMB] datetime NULL;
 
-- b00004140.no_voy | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00004140] ALTER COLUMN [no_voy] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00004140] ALTER COLUMN [no_voy] char(30) NULL;
 
-- b00004950.importe | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00004950] ALTER COLUMN [importe] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00004950] ALTER COLUMN [importe] bit NULL;
 
-- b00005730.presence | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005730] ALTER COLUMN [presence] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00005730] ALTER COLUMN [presence] char(4) NULL;
 
-- b00006240.fnum_fact | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[gb0000140] ALTER COLUMN [fnum_fact] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006240] ALTER COLUMN [fnum_fact] char(30) NULL;
 
-- b00006240.fnum_fact2 | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[gb0000140] ALTER COLUMN [fnum_fact2] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006240] ALTER COLUMN [fnum_fact2] char(30) NULL;
 
-- b00006250.chro_app | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[gb0000030] ALTER COLUMN [chro_app] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006250] ALTER COLUMN [chro_app] char(30) NULL;
 
-- b00006250.cod_asdi | type retenu: char(5) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[gb0000030] ALTER COLUMN [cod_asdi] char(5) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006250] ALTER COLUMN [cod_asdi] char(5) NULL;
 
-- b00006250.cod_tva | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[gb0000030] ALTER COLUMN [cod_tva] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006250] ALTER COLUMN [cod_tva] char(4) NULL;
 
-- b00006250.fnum_fact | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[gb0000030] ALTER COLUMN [fnum_fact] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006250] ALTER COLUMN [fnum_fact] char(30) NULL;
 
-- b00006260.num_bl | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[gb0000170] ALTER COLUMN [num_bl] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006260] ALTER COLUMN [num_bl] char(30) NULL;
 
-- b00006270.chro_app | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[gb0000060] ALTER COLUMN [chro_app] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006270] ALTER COLUMN [chro_app] char(30) NULL;
 
-- b00006650.cod_cont | type retenu: char(10) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00010950] ALTER COLUMN [cod_cont] char(10) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006650] ALTER COLUMN [cod_cont] char(10) NULL;
 
-- b00006650.cod_prod | type retenu: char(10) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00010950] ALTER COLUMN [cod_prod] char(10) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006650] ALTER COLUMN [cod_prod] char(10) NULL;
 
-- b00006650.lib_pai | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00010950] ALTER COLUMN [lib_pai] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006650] ALTER COLUMN [lib_pai] char(30) NULL;
 
-- b00006660.cod_qual | type retenu: numeric(4,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00009975] ALTER COLUMN [cod_qual] numeric(4,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006660] ALTER COLUMN [cod_qual] numeric(4,0) NULL;
 
-- b00006740.poidtot | type retenu: numeric(20,3) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00010930] ALTER COLUMN [poidtot] numeric(20,3) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00006740] ALTER COLUMN [poidtot] numeric(20,3) NULL;
 
-- b00009860.synch_mobi | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00011700] ALTER COLUMN [synch_mobi] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00009860] ALTER COLUMN [synch_mobi] bit NULL;
 
-- b00009860.synchro_mobi | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00011700] ALTER COLUMN [synchro_mobi] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00009860] ALTER COLUMN [synchro_mobi] bit NULL;
 
-- b00009900.synch_mobi | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00011730] ALTER COLUMN [synch_mobi] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00009900] ALTER COLUMN [synch_mobi] bit NULL;
 
-- b00009900.synchro_mobi | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00011730] ALTER COLUMN [synchro_mobi] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00009900] ALTER COLUMN [synchro_mobi] bit NULL;
 
-- b00009910.synch_mobi | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00011710] ALTER COLUMN [synch_mobi] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00009910] ALTER COLUMN [synch_mobi] bit NULL;
 
-- b00009910.synchro_mobi | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00011710] ALTER COLUMN [synchro_mobi] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00009910] ALTER COLUMN [synchro_mobi] bit NULL;
 
-- b00009930.synch_mobi | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00011070] ALTER COLUMN [synch_mobi] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00009930] ALTER COLUMN [synch_mobi] bit NULL;
 
-- b00009930.synchro_mobi | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00011070] ALTER COLUMN [synchro_mobi] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00009930] ALTER COLUMN [synchro_mobi] bit NULL;
 
-- b00009970.synch_mobi | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00011080] ALTER COLUMN [synch_mobi] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00009970] ALTER COLUMN [synch_mobi] bit NULL;
 
-- b00009970.synchro_mobi | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00011080] ALTER COLUMN [synchro_mobi] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00009970] ALTER COLUMN [synchro_mobi] bit NULL;
 
-- b00010150.weight | type retenu: numeric(20,3) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00010150] ALTER COLUMN [weight] numeric(20,3) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00010150] ALTER COLUMN [weight] numeric(20,3) NULL;
 
-- b00011000.ver | type retenu: char(100) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005560] ALTER COLUMN [VER] char(100) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00011000] ALTER COLUMN [ver] char(100) NULL;
 
-- b00012040.cod_cach | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005470] ALTER COLUMN [cod_cach] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012040] ALTER COLUMN [cod_cach] char(4) NULL;
 
-- b00012040.cod_pays | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005470] ALTER COLUMN [cod_pays] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012040] ALTER COLUMN [cod_pays] char(4) NULL;
 
-- b00012040.cod_sit | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005470] ALTER COLUMN [cod_sit] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012040] ALTER COLUMN [cod_sit] char(4) NULL;
 
-- b00012040.nocamp | type retenu: char(10) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005470] ALTER COLUMN [nocamp] char(10) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012040] ALTER COLUMN [nocamp] char(10) NULL;
 
-- b00012040.noot | type retenu: varchar(40) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005470] ALTER COLUMN [noot] varchar(40) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012040] ALTER COLUMN [noot] varchar(40) NULL;
 
-- b00012060.cod_cach | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [cod_cach] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [cod_cach] char(4) NULL;
 
-- b00012060.cod_cli | type retenu: varchar(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [cod_cli] varchar(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [cod_cli] varchar(30) NULL;
 
-- b00012060.cod_pays | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [cod_pays] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [cod_pays] char(4) NULL;
 
-- b00012060.cod_sit | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [cod_sit] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [cod_sit] char(4) NULL;
 
-- b00012060.lib_prod | type retenu: char(10) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [lib_prod] char(10) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [lib_prod] char(10) NULL;
 
-- b00012060.nocamp | type retenu: char(10) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [nocamp] char(10) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [nocamp] char(10) NULL;
 
-- b00012060.nofact_c | type retenu: varchar(40) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [nofact_c] varchar(40) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [nofact_c] varchar(40) NULL;
 
-- b00012060.nofact_p | type retenu: varchar(40) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [nofact_p] varchar(40) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [nofact_p] varchar(40) NULL;
 
-- b00012060.noot | type retenu: varchar(40) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [noot] varchar(40) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [noot] varchar(40) NULL;
 
-- b00012060.raison_cli | type retenu: varchar(60) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [raison_cli] varchar(60) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [raison_cli] varchar(60) NULL;
 
-- b00012060.ref_ot | type retenu: varchar(40) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [ref_ot] varchar(40) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [ref_ot] varchar(40) NULL;
 
-- b00012060.transitair | type retenu: varchar(100) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005550] ALTER COLUMN [transitair] varchar(100) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012060] ALTER COLUMN [transitair] varchar(100) NULL;
 
-- b00012070.tare_sac1 | type retenu: numeric(20,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005590] ALTER COLUMN [tare_sac1] numeric(20,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012070] ALTER COLUMN [tare_sac1] numeric(20,0) NULL;
 
-- b00012080.cod_cach | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005540] ALTER COLUMN [cod_cach] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012080] ALTER COLUMN [cod_cach] char(4) NULL;
 
-- b00012080.cod_pays | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005540] ALTER COLUMN [cod_pays] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012080] ALTER COLUMN [cod_pays] char(4) NULL;
 
-- b00012080.cod_sit | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005540] ALTER COLUMN [cod_sit] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012080] ALTER COLUMN [cod_sit] char(4) NULL;
 
-- b00012080.nocamp | type retenu: char(10) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00005540] ALTER COLUMN [nocamp] char(10) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00012080] ALTER COLUMN [nocamp] char(10) NULL;
 
-- b00013870.heur_maint | type retenu: char(10) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00013870] ALTER COLUMN [heur_maint] char(10) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00013870] ALTER COLUMN [heur_maint] char(10) NULL;
 
-- b00013920.statut | type retenu: char(150) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00013920] ALTER COLUMN [statut] char(150) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00013920] ALTER COLUMN [statut] char(150) NULL;
 
-- b00014080.statut | type retenu: char(15) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00014080] ALTER COLUMN [statut] char(15) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[b00014080] ALTER COLUMN [statut] char(15) NULL;
 
-- p00000004.exti | type retenu: varbinary(max) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000004] ALTER COLUMN [exti] varbinary(max) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000004] ALTER COLUMN [exti] varbinary(max) NULL;
 
-- p00000004.photo | type retenu: varbinary(max) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000004] ALTER COLUMN [PHOTO] varbinary(max) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000004] ALTER COLUMN [photo] varbinary(max) NULL;
 
-- p00000020.photo_file | type retenu: varbinary(max) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000020] ALTER COLUMN [PHOTO_FILE] varbinary(max) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000020] ALTER COLUMN [photo_file] varbinary(max) NULL;
 
-- p00000020.photo_fne | type retenu: varbinary(max) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000020] ALTER COLUMN [photo_fne] varbinary(max) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000020] ALTER COLUMN [photo_fne] varbinary(max) NULL;
 
-- p00000023.code_ut | type retenu: char(255) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000023] ALTER COLUMN [code_ut] char(255) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000023] ALTER COLUMN [code_ut] char(255) NULL;
 
-- p00000023.email | type retenu: varchar(255) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000023] ALTER COLUMN [email] varchar(255) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000023] ALTER COLUMN [email] varchar(255) NULL;
 
-- p00000072.cod_sac | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000072] ALTER COLUMN [cod_sac] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000072] ALTER COLUMN [cod_sac] char(4) NULL;
 
-- p00000090.nolot | type retenu: numeric(20,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000090] ALTER COLUMN [nolot] numeric(20,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000090] ALTER COLUMN [nolot] numeric(20,0) NULL;
 
-- p00000092.criter_fne | type retenu: numeric(2,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000092] ALTER COLUMN [criter_fne] numeric(2,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000092] ALTER COLUMN [criter_fne] numeric(2,0) NULL;
 
-- p00000200.cod_form | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000200] ALTER COLUMN [cod_form] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000200] ALTER COLUMN [cod_form] char(30) NULL;
 
-- p00000250.cod_sect | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000250] ALTER COLUMN [cod_sect] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000250] ALTER COLUMN [cod_sect] char(30) NULL;
 
-- p00000607.no_nav | type retenu: char(10) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000607] ALTER COLUMN [no_nav] char(10) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000607] ALTER COLUMN [no_nav] char(10) NULL;
 
-- p00000610.no_group | type retenu: numeric(20,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000610] ALTER COLUMN [no_group] numeric(20,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000610] ALTER COLUMN [no_group] numeric(20,0) NULL;
 
-- p00000610.no_voy | type retenu: numeric(20,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000610] ALTER COLUMN [no_voy] numeric(20,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000610] ALTER COLUMN [no_voy] numeric(20,0) NULL;
 
-- p00000610.noce | type retenu: numeric(20,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000610] ALTER COLUMN [noce] numeric(20,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000610] ALTER COLUMN [noce] numeric(20,0) NULL;
 
-- p00000610.nocont | type retenu: numeric(20,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000610] ALTER COLUMN [nocont] numeric(20,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000610] ALTER COLUMN [nocont] numeric(20,0) NULL;
 
-- p00000610.noenr | type retenu: numeric(20,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000610] ALTER COLUMN [noenr] numeric(20,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000610] ALTER COLUMN [noenr] numeric(20,0) NULL;
 
-- p00000610.noot | type retenu: numeric(20,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000610] ALTER COLUMN [noot] numeric(20,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000610] ALTER COLUMN [noot] numeric(20,0) NULL;
 
-- p00000610.noprof | type retenu: numeric(20,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00000610] ALTER COLUMN [noprof] numeric(20,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00000610] ALTER COLUMN [noprof] numeric(20,0) NULL;
 
-- p00001000.cod_sec | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00001000] ALTER COLUMN [cod_sec] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001000] ALTER COLUMN [cod_sec] char(30) NULL;
 
-- p00001040.cod_dest | type retenu: numeric(4,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00001040] ALTER COLUMN [cod_dest] numeric(4,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001040] ALTER COLUMN [cod_dest] numeric(4,0) NULL;
 
-- p00001040.cod_pays | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00000955] ALTER COLUMN [cod_pays] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001040] ALTER COLUMN [cod_pays] char(4) NULL;
 
-- p00001040.cod_pays | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00001040] ALTER COLUMN [cod_pays] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001040] ALTER COLUMN [cod_pays] char(4) NULL;
 
-- p00001040.cod_sit | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00000955] ALTER COLUMN [cod_sit] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001040] ALTER COLUMN [cod_sit] char(4) NULL;
 
-- p00001040.cod_sit | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00001040] ALTER COLUMN [cod_sit] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001040] ALTER COLUMN [cod_sit] char(4) NULL;
 
-- p00001040.no_arb | type retenu: numeric(20,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00001040] ALTER COLUMN [no_arb] numeric(20,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001040] ALTER COLUMN [no_arb] numeric(20,0) NULL;
 
-- p00001040.nobl_int | type retenu: numeric(20,0) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[b00000955] ALTER COLUMN [nobl_int] numeric(20,0) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001040] ALTER COLUMN [nobl_int] numeric(20,0) NULL;
 
-- p00001070.sit_fam | type retenu: char(40) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00001070] ALTER COLUMN [sit_fam] char(40) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001070] ALTER COLUMN [sit_fam] char(40) NULL;
 
-- p00001180.cod_typb | type retenu: char(30) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00004280] ALTER COLUMN [cod_typb] char(30) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001180] ALTER COLUMN [cod_typb] char(30) NULL;
 
-- p00001290.cod_pays | type retenu: char(4) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00001290] ALTER COLUMN [cod_pays] char(4) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001290] ALTER COLUMN [cod_pays] char(4) NULL;
 
-- p00001970.importe | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[MP0000680] ALTER COLUMN [importe] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00001970] ALTER COLUMN [importe] bit NULL;
 
-- p00004560.importe | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00008040] ALTER COLUMN [importe] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00004560] ALTER COLUMN [importe] bit NULL;
 
-- p00023210.code_ut | type retenu: char(255) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00023210] ALTER COLUMN [code_ut] char(255) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00023210] ALTER COLUMN [code_ut] char(255) NULL;
 
-- p00023230.heur_deb | type retenu: time | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00023230] ALTER COLUMN [heur_deb] time NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00023230] ALTER COLUMN [heur_deb] time NULL;
 
-- p00023230.heur_fin | type retenu: time | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00023230] ALTER COLUMN [heur_fin] time NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00023230] ALTER COLUMN [heur_fin] time NULL;
 
-- p00023230.lib_app | type retenu: nvarchar(max) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00023230] ALTER COLUMN [lib_app] nvarchar(max) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00023230] ALTER COLUMN [lib_app] nvarchar(max) NULL;
 
-- p00023230.lib_niv | type retenu: nvarchar(max) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00023230] ALTER COLUMN [lib_niv] nvarchar(max) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00023230] ALTER COLUMN [lib_niv] nvarchar(max) NULL;
 
-- p00024310.serveur_destina | type retenu: char(100) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00024310] ALTER COLUMN [serveur_destina] char(100) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00024310] ALTER COLUMN [serveur_destina] char(100) NULL;
 
-- p00024310.serveur_source | type retenu: char(100) | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00024310] ALTER COLUMN [serveur_source] char(100) NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00024310] ALTER COLUMN [serveur_source] char(100) NULL;
 
-- p00024310.suspendre | type retenu: bit | Windows: Agromex_base_ACC | Web: AGROMEX_WEB_ACCZAD
ALTER TABLE [AGROMEX_WEB_ACCZAD].dbo.[p00024310] ALTER COLUMN [suspendre] bit NULL;
ALTER TABLE [Agromex_base_ACC].dbo.[p00024310] ALTER COLUMN [suspendre] bit NULL;
 