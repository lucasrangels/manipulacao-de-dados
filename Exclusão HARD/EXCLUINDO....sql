--BLOCO 001

SELECT ns.exclusaoconstraints();
ANALYZE VERBOSE;

CREATE TABLE ids_docfis AS
SELECT id FROM ns.df_docfis WHERE id_estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032'));
DELETE FROM ns.df_docfis WHERE id_estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032'));

CREATE TABLE ids_itensmov AS
SELECT id FROM estoque.itens_mov WHERE id_estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032'));
DELETE FROM estoque.itens_mov WHERE id_estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032'));

CREATE TABLE ids_dfitens AS
SELECT id FROM ns.df_itens WHERE id_docfis IN (SELECT id FROM ids_docfis);
DELETE FROM ns.df_itens WHERE id_docfis IN (SELECT id FROM ids_docfis);

CREATE TABLE ids_ecf_rzitens AS
SELECT id FROM scritta.ecf_rzitens WHERE id_reducaoz IN (SELECT id FROM scritta.ecf_rz WHERE id_estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032')));
DELETE FROM scritta.ecf_rzitens WHERE id_reducaoz IN (SELECT id FROM scritta.ecf_rz WHERE id_estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032')));

TRUNCATE conversor.cwmovest;

CREATE TABLE ids_lf_lanfis AS
SELECT id FROM scritta.lf_lanfis WHERE id_estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032'));
DELETE FROM scritta.lf_lanfis WHERE id_estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032'));

CREATE TABLE ids_contabilizacoes AS
SELECT contabilizacao FROM contabilizacao.contabilizacoes WHERE estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032'));
DELETE FROM contabilizacao.contabilizacoes WHERE estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032'));

CREATE TABLE ecf_rzcf AS
SELECT id FROM scritta.ecf_rzcf WHERE id_reducaoz IN (SELECT id FROM scritta.ecf_rz WHERE id_estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032')));
DELETE FROM scritta.ecf_rzcf WHERE id_reducaoz IN (SELECT id FROM scritta.ecf_rz WHERE id_estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032')));

DELETE FROM estoque.itens_mov WHERE id_itemlanfis IN (SELECT id FROM scritta.lf_itens WHERE id_lanfis IN (SELECT id FROM ids_lf_lanfis));
DELETE FROM scritta.dde_notas WHERE chaveitem IN (SELECT id FROM scritta.lf_itens WHERE id_lanfis IN (SELECT id FROM ids_lf_lanfis));
DELETE FROM scritta.lf_itens WHERE id_lanfis IN (SELECT id FROM ids_lf_lanfis);
DELETE FROM contabilizacao.sumario_contabilizacoes WHERE contabilizacao IN (SELECT contabilizacao FROM ids_contabilizacoes);
DELETE FROM contabilizacao.lancamentoscontabeis WHERE contabilizacao IN (SELECT contabilizacao FROM ids_contabilizacoes);
DELETE FROM scritta.df_lancpc WHERE id_docfis IN (SELECT id FROM ids_docfis);
DELETE FROM scritta.lf_lanfis WHERE id_docfis IN (SELECT id FROM ids_docfis);
DELETE FROM scritta.lanaju WHERE id_docfis IN (SELECT id FROM ids_docfis);
DELETE FROM ns.df_formapagamentos WHERE id_docfis IN (SELECT id FROM ids_docfis);
DELETE FROM ns.df_linhas WHERE id_docfis IN (SELECT id FROM ids_docfis);
DELETE FROM estoque.itens_mov WHERE id_docfis IN (SELECT id FROM ids_docfis);
DELETE FROM estoque.itens_mov WHERE id_itemrzcf IN (SELECT id FROM ids_ecf_rzitens);
DELETE FROM estoque.itens_mov WHERE id_itemdocfis IN (SELECT id FROM ns.df_itens WHERE id_docfis IN (SELECT id FROM ids_docfis));
DELETE FROM contabil.bensexercicios WHERE bem IN (SELECT bem FROM ns.bens WHERE itemnota IN (SELECT id FROM ns.df_itens WHERE id_docfis IN (SELECT id FROM ids_docfis)));
UPDATE contabil.bensocorrencias SET bemincorporado = NULL WHERE bemincorporado IN (SELECT bem FROM ns.bens WHERE itemnota IN (SELECT id FROM ns.df_itens WHERE id_docfis IN (SELECT id FROM ids_docfis)));
DELETE FROM contabil.bensocorrencias WHERE bem IN (SELECT bem FROM ns.bens WHERE itemnota IN (SELECT id FROM ns.df_itens WHERE id_docfis IN (SELECT id FROM ids_docfis)));
UPDATE ns.bens SET bemagregador = NULL WHERE bemagregador IN (SELECT bem FROM ns.bens WHERE itemnota IN (SELECT id FROM ns.df_itens WHERE id_docfis IN (SELECT id FROM ids_docfis)));
UPDATE ns.bens SET principal = NULL WHERE principal IN (SELECT bem FROM ns.bens WHERE itemnota IN (SELECT id FROM ns.df_itens WHERE id_docfis IN (SELECT id FROM ids_docfis)));
DELETE FROM ns.bens WHERE itemnota IN (SELECT id FROM ns.df_itens WHERE id_docfis IN (SELECT id FROM ids_docfis));
DELETE FROM ns.df_itens WHERE id_docfis IN (SELECT id FROM ids_docfis);
DELETE FROM scritta.ecf_rzitens WHERE id_reducaoz IN (SELECT id FROM scritta.ecf_rz WHERE id_estabelecimento IN (SELECT estabelecimento FROM ns.estabelecimentos WHERE empresa <> (SELECT empresa FROM ns.empresas WHERE codigo = '032')));

VACUUM FULL VERBOSE;

REINDEX DATABASE robertocarneiro_thoper_2;

ANALYZE VERBOSE;

--BLOCO 002

SELECT ns.apagarempresa_hard(ARRAY['f46866d0-6ac2-4b5a-9a97-8fff5436ca03','0ce80596-d6c7-49c4-b87a-6fbe25b95fe4','c29a04b4-e610-4d4f-b5d4-6b091a9fc388','9b8cb229-4b91-4494-952e-a24cadc424fa','fcf0a6ea-4858-480d-8c7f-585f656bcfaa','c49da9ae-acfb-4009-acf7-2c9dc319681e','e0d5d6c2-5148-4da6-838d-6cded8400f61','ce559b5b-d824-4218-927a-15dce4e84ba1','1381aa84-c355-44c0-84e1-27c5bbb49e2b','9d338183-2947-489f-9d0a-a455f2c058f0','4063d175-46ce-4848-a0b0-a7851a2ae823','62a39efd-1d02-4cdd-bcf8-03112ace620c','915b9b82-f251-4b2c-bbef-0958cda319b0','6fb7e2ea-eb6e-4649-b277-c738a6b32356','d9872f1c-4eb8-4ecc-bfcf-1de152d97bb2','79c76249-f8c1-4621-bfdd-36794f95e738','4979724f-461c-402d-8b69-7c2bea1e2aa0','70776616-6f0c-41d5-bb0b-0ce6fda55a14','9ef0533d-eccb-40d7-9dfa-ede3977d4e97','e6126eea-af5b-4ec1-b4ba-6d8273edc553','3729cdf1-8647-43ef-9bd2-f03c20550141','579ab02f-3681-4c97-ab0e-148febe1bbd7','91e041a5-be73-4cf1-bbc8-7e458fa6ef55','550cfc3c-7ce7-4f88-906b-e461ce6da9a1','8f3bcf3b-b9ea-4a41-b8d5-b48cb6275be5','07897c78-deb0-47b6-9b7d-853965cee361','ec959976-3789-4ab9-9b9f-09ec0101f79a','6cb3d26d-bbfb-4a9f-9939-05670f04f003']::UUID[]);

--BLOCO 003

VACUUM FULL VERBOSE;

REINDEX DATABASE robertocarneiro_thoper_2;

ANALYZE VERBOSE;

--BLOCO 004

INSERT INTO estoque.locaisdeestoques (localdeestoque,estabelecimento,codigo,nome,tipo,enderecodiferente)
SELECT DISTINCT ON (localdeestoque) localdeestoque, id_estabelecimento,'OUTROS','ESTOQUE OUTROS',0,FALSE
FROM estoque.itens_mov
WHERE localdeestoque NOT IN (SELECT localdeestoque FROM estoque.locaisdeestoques);

--BLOCO IGNORADO

/* IGNORAR TUDO QUE ESTIVER AQUI DENTRO

INSERT INTO estoque.locaisdeestoques (estabelecimento,codigo,nome,tipo,enderecodiferente)
SELECT estabelecimento,'OUTROS','ESTOQUE OUTROS',0,FALSE
FROM ns.estabelecimentos;

CREATE TEMP TABLE itens_mov AS
SELECT * FROM estoque.itens_mov;

UPDATE itens_mov
SET localdeestoque = locaisdeestoques.localdeestoque
FROM estoque.locaisdeestoques
WHERE itens_mov.id_estabelecimento = locaisdeestoques.estabelecimento
AND locaisdeestoques.codigo = 'OUTROS'
AND itens_mov.localdeestoque NOT IN (SELECT localdeestoque FROM estoque.locaisdeestoques);

TRUNCATE estoque.itens_mov;

INSERT INTO estoque.itens_mov
SELECT * FROM itens_mov;

IGNORAR ATÉ AQUI*/

--BLOCO 005

SELECT ns.criacaoconstraints();

--BLOCO 006 (VALIDAR ANTES DE EXECUTAR ESSE BLOCO)

DROP TABLE ids_docfis;

DROP TABLE ids_itensmov;

DROP TABLE ids_dfitens;

DROP TABLE ids_ecf_rzitens;

DROP TABLE ids_lf_lanfis;

DROP TABLE ids_contabilizacoes;

DROP TABLE ecf_rzcf;

/*
select table_schema AS Esquema,
table_name AS Tabela,
pg_size_pretty(pg_relation_size('"'||table_schema||'"."'||table_name||'"')::bigint) AS Tamanho,
pg_relation_size('"'||table_schema||'"."'||table_name||'"') AS Tamanho_Puro
from information_schema.tables
order by 4 DESC

SELECT DISTINCT 
    const.conrelid, 
	CONCAT(nsp.nspname, '.', tabela.relname)::CHARACTER VARYING tabela,
	(coluna.attname)::CHARACTER VARYING campochave
FROM tmp_pg_constraint const 
	INNER JOIN tmp_pg_class tabela ON tabela.oid = const.conrelid 
	INNER JOIN tmp_pg_attribute coluna ON coluna.attrelid = const.conrelid AND conkey[1] = coluna.attnum
	INNER JOIN tmp_pg_namespace nsp ON tabela.relnamespace = nsp.oid
	WHERE const.confrelid::CHARACTER VARYING = 227234141::CHARACTER VARYING AND const.contype = 'f' 
ORDER BY const.conrelid DESC 
*/