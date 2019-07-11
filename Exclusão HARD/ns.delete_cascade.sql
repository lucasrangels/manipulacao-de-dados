-- Function: ns.delete_cascade(character varying, character varying, uuid[])

-- DROP FUNCTION ns.delete_cascade(character varying, character varying, uuid[]);

CREATE OR REPLACE FUNCTION ns.delete_cascade_hard(
    a_tabela character varying,
    a_campo character varying,
    a_valores uuid[])
  RETURNS void AS
$BODY$  
DECLARE 
	DECLARE OID_POSTGRES_TABELA_FILHA INTEGER;
	DECLARE NOME_PK_TABELAFILHAPAI CHARACTER VARYING;
	DECLARE REGTABELAS_DEPENDENTES RECORD;   
	DECLARE VAR_IDS UUID[];
	DECLARE VAR_IDSSTR VARCHAR;
	DECLARE VAR_VALORESSTR VARCHAR;
	DECLARE VAR_QTDLINHAS_TABELA INTEGER;
	DECLARE MSG TEXT;
	DECLARE TMP_TABELAS_DEPENDENTES TEXT = '';
	DECLARE _CONSTRAINTS RECORD;
	DECLARE _CONST RECORD;
	DECLARE _QUERY CHARACTER VARYING = '';

BEGIN
	-- MSG = 'INSERT INTO PUBLIC.EXCLUSAO_PARAMETROS (tabela_filha_do_pai, nome_fk_pai, valor_fk_pai) VALUES ('''||A_TABELA||''','''||A_CAMPO||''', '''||A_VALORES::TEXT||''');';
-- 	PERFORM dblink(msg);

	IF LOWER(TRIM(a_tabela)) IN ('ns.usuarios', 'ns.empresas') THEN
		RETURN;
	END IF;
	
	IF a_tabela IN ('ns.df_docfis','estoque.itens_mov','ns.df_itens','scritta.ecf_rzitens','scritta.lf_lanfis','contabilizacao.contabilizacoes','scritta.ecf_rzcf') THEN
		IF a_tabela = 'ns.df_docfis' THEN
			EXECUTE 'SELECT COUNT(1) FROM ids_docfis;' INTO VAR_QTDLINHAS_TABELA;
		ELSIF a_tabela = 'estoque.itens_mov' THEN
			EXECUTE 'SELECT COUNT(1) FROM ids_itensmov;' INTO VAR_QTDLINHAS_TABELA;
		ELSIF a_tabela = 'ns.df_itens' THEN
			EXECUTE 'SELECT COUNT(1) FROM ids_dfitens;' INTO VAR_QTDLINHAS_TABELA;
		ELSIF a_tabela = 'scritta.ecf_rzitens' THEN
			EXECUTE 'SELECT COUNT(1) FROM ids_ecf_rzitens;' INTO VAR_QTDLINHAS_TABELA;
		ELSIF a_tabela = 'scritta.lf_lanfis' THEN
			EXECUTE 'SELECT COUNT(1) FROM ids_lf_lanfis;' INTO VAR_QTDLINHAS_TABELA;
		ELSIF a_tabela = 'contabilizacao.contabilizacoes' THEN
			EXECUTE 'SELECT COUNT(1) FROM ids_contabilizacoes;' INTO VAR_QTDLINHAS_TABELA;
		ELSE
			EXECUTE 'SELECT COUNT(1) FROM ecf_rzcf;' INTO VAR_QTDLINHAS_TABELA;
		END IF;
		
	ELSE
		EXECUTE 'SELECT COUNT(*) FROM '|| a_tabela ||';' INTO VAR_QTDLINHAS_TABELA;
	END IF;

	IF (VAR_QTDLINHAS_TABELA) = 0 THEN
		RETURN;
	END IF;

	EXECUTE 
		'SELECT TABREF.OID, A.ATTNAME FROM TMP_PG_CLASS TABREF ' ||
		'INNER JOIN TMP_PG_NAMESPACE SC  ' || 'ON (TABREF.RELNAMESPACE = SC.OID )  ' ||
		'INNER JOIN TMP_PG_INDEX I ' || 'ON I.INDRELID = TABREF.OID ' ||
		'INNER JOIN TMP_PG_ATTRIBUTE A ON A.ATTRELID = I.INDRELID  AND A.ATTNUM = ANY(I.INDKEY) ' ||
		'WHERE CONCAT( SC.NSPNAME,''.'', RELNAME ) = ' || QUOTE_LITERAL(a_tabela) ||
		  'AND  I.INDISPRIMARY ' 
	INTO OID_POSTGRES_TABELA_FILHA, NOME_PK_TABELAFILHAPAI;

	/*TABELAS QUE NãO POSSUEM PK*/
	IF a_tabela = 'ns.estabelecimentoscfops' THEN 
		NOME_PK_TABELAFILHAPAI := 'cfop';
	END IF; 

	IF a_tabela = 'scritta.sn_cfg' THEN 
		NOME_PK_TABELAFILHAPAI := 'id_empresa';
	END IF; 

	IF a_tabela = 'importacao.titulos_importacoes' THEN 
		NOME_PK_TABELAFILHAPAI := 'id_importacao';
	END IF;

	IF a_tabela = 'ns.df_autorizados' THEN
		NOME_PK_TABELAFILHAPAI := 'df_autorizado';
	END IF;

	IF COALESCE(NOME_PK_TABELAFILHAPAI, '') = '' THEN 
		RAISE 'TABELA % SEM PK', a_tabela;
	END IF;

	SELECT COALESCE(NOME_PK_TABELAFILHAPAI, 'ID') INTO NOME_PK_TABELAFILHAPAI;
		
	SELECT array_to_string(array_agg('''' || valor::VARCHAR || '''::uuid'), ',') 
	INTO VAR_VALORESSTR
	FROM UNNEST(a_valores) AS valor;

	RAISE NOTICE 'TABELA: % - CAMPO TABELA PAI: % - CAMPO TABELA FILHA: %',a_tabela,NOME_PK_TABELAFILHAPAI,a_campo;

	IF a_tabela = 'ns.df_docfis' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
		EXECUTE 'WITH registros AS (
				 SELECT id AS registro FROM ids_docfis 
				 UNION
				 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
			 SELECT array_agg(registro) FROM registros'
		INTO VAR_IDS;
	ELSIF a_tabela = 'estoque.itens_mov' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
		EXECUTE 'WITH registros AS (
				 SELECT id AS registro FROM ids_itensmov 
				 UNION
				 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
			 SELECT array_agg(registro) FROM registros'
		INTO VAR_IDS;
	ELSIF a_tabela = 'ns.df_itens' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
		EXECUTE 'WITH registros AS (
				 SELECT id AS registro FROM ids_dfitens 
				 UNION
				 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
			 SELECT array_agg(registro) FROM registros'
		INTO VAR_IDS;
	ELSIF a_tabela = 'scritta.ecf_rzitens' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
		EXECUTE 'WITH registros AS (
				 SELECT id AS registro FROM ids_ecf_rzitens 
				 UNION
				 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
			 SELECT array_agg(registro) FROM registros'
		INTO VAR_IDS;
	ELSIF a_tabela = 'scritta.lf_lanfis' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
		EXECUTE 'WITH registros AS (
				 SELECT id AS registro FROM ids_lf_lanfis 
				 UNION
				 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
			 SELECT array_agg(registro) FROM registros'
		INTO VAR_IDS;
	ELSIF a_tabela = 'contabilizacao.contabilizacoes' AND NOME_PK_TABELAFILHAPAI = 'contabilizacao' THEN
		EXECUTE 'WITH registros AS (
				 SELECT contabilizacao AS registro FROM ids_contabilizacoes 
				 UNION
				 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
			 SELECT array_agg(registro) FROM registros'
		INTO VAR_IDS;
	ELSIF a_tabela = 'scritta.ecf_rzcf' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
		EXECUTE 'WITH registros AS (
				 SELECT id AS registro FROM ecf_rzcf 
				 UNION
				 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
			 SELECT array_agg(registro) FROM registros'
		INTO VAR_IDS;
	ELSE
		EXECUTE 'SELECT array_agg(' || NOME_PK_TABELAFILHAPAI || ') FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || '])'
		INTO VAR_IDS;
	END IF;

	IF VAR_IDS IS NULL THEN
		RETURN;
	END IF;
	
	SELECT array_to_string(array_agg('''' || valor::VARCHAR || '''::uuid'), ',') 
	INTO VAR_IDSSTR
	FROM UNNEST(VAR_IDS) AS valor;

	FOR REGTABELAS_DEPENDENTES IN
	(
		SELECT DISTINCT 
		    const.conrelid, 
			CONCAT(nsp.nspname, '.', tabela.relname)::CHARACTER VARYING tabela,
			(coluna.attname)::CHARACTER VARYING campochave
		FROM tmp_pg_constraint const 
			INNER JOIN tmp_pg_class tabela ON tabela.oid = const.conrelid 
			INNER JOIN tmp_pg_attribute coluna ON coluna.attrelid = const.conrelid AND conkey[1] = coluna.attnum
			INNER JOIN tmp_pg_namespace nsp ON tabela.relnamespace = nsp.oid
			WHERE const.confrelid::CHARACTER VARYING = OID_POSTGRES_TABELA_FILHA::CHARACTER VARYING AND const.contype = 'f' 
		ORDER BY const.conrelid DESC 
	) 
	LOOP
		RAISE NOTICE 'TABELA: %',a_tabela;
		RAISE NOTICE 'TABELA DEPENDENTE: %',REGTABELAS_DEPENDENTES.tabela;
		RAISE NOTICE 'TABELA CAMPO: %',REGTABELAS_DEPENDENTES.campochave;

		IF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'scritta.lf_itens' AND TRIM(a_tabela) = 'scritta.lf_lanfis' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'contabilizacao.sumario_contabilizacoes' AND TRIM(a_tabela) = 'contabilizacao.contabilizacoes' THEN

			CONTINUE;

		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'contabilizacao.lancamentoscontabeis' AND TRIM(a_tabela) = 'contabilizacao.contabilizacoes' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'scritta.df_lancpc' AND TRIM(a_tabela) = 'ns.df_docfis' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'scritta.lf_lanfis' AND TRIM(a_tabela) = 'ns.df_docfis' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'scritta.lanaju' AND TRIM(a_tabela) = 'ns.df_docfis' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'ns.df_formapagamentos' AND TRIM(a_tabela) = 'ns.df_docfis' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'ns.df_linhas' AND TRIM(a_tabela) = 'ns.df_docfis' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'estoque.itens_mov' AND TRIM(a_tabela) = 'ns.df_docfis' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'ns.df_itens' AND TRIM(a_tabela) = 'ns.df_docfis' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'contabilizacao.contabilizacoes' AND TRIM(a_tabela) = 'ns.df_docfis' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'scritta.ecf_rzitens' AND TRIM(a_tabela) = 'scritta.ecf_rz' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = 'scritta.ecf_rzitens' AND TRIM(a_tabela) = 'scritta.ecf_rzcf' THEN

			CONTINUE;
		
		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) = TRIM(a_tabela) THEN
				
				IF a_tabela = 'ns.df_docfis' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
					EXECUTE 'WITH registros AS (
							 SELECT id AS registro FROM ids_docfis 
							 UNION
							 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
						 UPDATE ' || REGTABELAS_DEPENDENTES.tabela || 
						 ' SET ' || REGTABELAS_DEPENDENTES.campochave || ' = NULL ' ||
						 'WHERE ' || REGTABELAS_DEPENDENTES.campochave || ' IN (SELECT registro FROM registros)';
				ELSIF a_tabela = 'estoque.itens_mov' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
					EXECUTE 'WITH registros AS (
							 SELECT id AS registro FROM ids_itensmov 
							 UNION
							 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
						 UPDATE ' || REGTABELAS_DEPENDENTES.tabela || 
						 ' SET ' || REGTABELAS_DEPENDENTES.campochave || ' = NULL ' ||
						 'WHERE ' || REGTABELAS_DEPENDENTES.campochave || ' IN (SELECT registro FROM registros)';
				ELSIF a_tabela = 'ns.df_itens' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
					EXECUTE 'WITH registros AS (
							 SELECT id AS registro FROM ids_dfitens 
							 UNION
							 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
						 UPDATE ' || REGTABELAS_DEPENDENTES.tabela || 
						 ' SET ' || REGTABELAS_DEPENDENTES.campochave || ' = NULL ' ||
						 'WHERE ' || REGTABELAS_DEPENDENTES.campochave || ' IN (SELECT registro FROM registros)';
				ELSIF a_tabela = 'scritta.ecf_rzitens' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
					EXECUTE 'WITH registros AS (
							 SELECT id AS registro FROM ids_ecf_rzitens 
							 UNION
							 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
						 UPDATE ' || REGTABELAS_DEPENDENTES.tabela || 
						 ' SET ' || REGTABELAS_DEPENDENTES.campochave || ' = NULL ' ||
						 'WHERE ' || REGTABELAS_DEPENDENTES.campochave || ' IN (SELECT registro FROM registros)';
				ELSIF a_tabela = 'scritta.lf_lanfis' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
					EXECUTE 'WITH registros AS (
							 SELECT id AS registro FROM ids_lf_lanfis 
							 UNION
							 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
						 UPDATE ' || REGTABELAS_DEPENDENTES.tabela || 
						 ' SET ' || REGTABELAS_DEPENDENTES.campochave || ' = NULL ' ||
						 'WHERE ' || REGTABELAS_DEPENDENTES.campochave || ' IN (SELECT registro FROM registros)';
				ELSIF a_tabela = 'contabilizacao.contabilizacoes' AND NOME_PK_TABELAFILHAPAI = 'contabilizacao' THEN
					EXECUTE 'WITH registros AS (
							 SELECT contabilizacao AS registro FROM ids_contabilizacoes 
							 UNION
							 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
						 UPDATE ' || REGTABELAS_DEPENDENTES.tabela || 
						 ' SET ' || REGTABELAS_DEPENDENTES.campochave || ' = NULL ' ||
						 'WHERE ' || REGTABELAS_DEPENDENTES.campochave || ' IN (SELECT registro FROM registros)';
				ELSIF a_tabela = 'scritta.ecf_rzcf' AND NOME_PK_TABELAFILHAPAI = 'id' THEN
					EXECUTE 'WITH registros AS (
							 SELECT id AS registro FROM ecf_rzcf 
							 UNION
							 SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))
						 UPDATE ' || REGTABELAS_DEPENDENTES.tabela || 
						 ' SET ' || REGTABELAS_DEPENDENTES.campochave || ' = NULL ' ||
						 'WHERE ' || REGTABELAS_DEPENDENTES.campochave || ' IN (SELECT registro FROM registros)';
				ELSE
					EXECUTE 'UPDATE ' || REGTABELAS_DEPENDENTES.tabela || 
						' SET ' || REGTABELAS_DEPENDENTES.campochave || ' = NULL ' ||
						' WHERE ' || REGTABELAS_DEPENDENTES.campochave || ' IN (SELECT ' || NOME_PK_TABELAFILHAPAI || ' FROM ' || a_tabela || ' WHERE ' || a_campo || ' = ANY(ARRAY[' || VAR_VALORESSTR || ']))';
				END IF;

		ELSIF TRIM(REGTABELAS_DEPENDENTES.tabela) <> ('ns.usuarios') THEN

			RAISE NOTICE 'Tabela % dependente da % sendo excluída...',REGTABELAS_DEPENDENTES.tabela,a_tabela;

			PERFORM ns.delete_cascade_hard(REGTABELAS_DEPENDENTES.tabela, REGTABELAS_DEPENDENTES.campochave, VAR_IDS);

			RAISE NOTICE 'Tabela % dependente da % excluída...',REGTABELAS_DEPENDENTES.tabela,a_tabela;

		END IF;

	END LOOP;
	
	IF a_tabela IN ('ns.df_docfis','estoque.itens_mov','ns.df_itens','scritta.ecf_rzitens','scritta.lf_lanfis','contabilizacao.contabilizacoes','scritta.ecf_rzcf') THEN
		RETURN;
	END IF;

	EXECUTE 'DELETE FROM ' || a_tabela ||' WHERE '|| a_campo ||' = ANY(ARRAY[' || VAR_VALORESSTR || ']);';

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION ns.delete_cascade_hard(character varying, character varying, uuid[])
  OWNER TO group_nasajon;
