-- Function: ns.apagarempresa(uuid[])

-- DROP FUNCTION ns.apagarempresa(uuid[]);

CREATE OR REPLACE FUNCTION ns.apagarempresa_hard(a_empresas uuid[])
  RETURNS void AS
$BODY$
DECLARE 
	REG_TABELA_FILHA_EMPRESA RECORD;
	REG_INFO_CAMPOS  RECORD;
	CHAVE CHARACTER VARYING;
	VAR_OID_NS_EMPRESAS OID;
	ID_EMPRESA_TEMP TEXT;
	VAR_EMPRESAS_STR VARCHAR;
BEGIN
    --SET CONSTRAINTS ALL DEFERRED;

    BEGIN

	DROP TABLE IF EXISTS TB_FK_ESTAB;
	CREATE TEMPORARY TABLE TB_FK_ESTAB
	(
		campochave CHARACTER VARYING(38), 
		objid OID, 
		tabela CHARACTER VARYING  
	);

	DROP TABLE IF EXISTS TMP_TABELAS_FILHAS_EMPRESA;
	CREATE TEMPORARY TABLE TMP_TABELAS_FILHAS_EMPRESA
	(
		id OID 
	);

	SELECT tab.oid
	INTO VAR_OID_NS_EMPRESAS
	FROM tmp_pg_class tab
		INNER JOIN tmp_pg_namespace sc ON tab.relnamespace = sc.oid
	WHERE CONCAT(sc.nspname, '.', tab.relname) = 'ns.empresas';

	WITH OIDS AS 
	(
		WITH TABELASFILHASEMPRESA AS 
		( 
			SELECT 
				coluna.attname, 
				CONCAT(schemaref.nspname, '.', tabelaref.relname) AS tabelafilha

			FROM tmp_pg_namespace schema
				INNER JOIN tmp_pg_class tabela ON schema.oid = tabela.relnamespace
				INNER JOIN tmp_pg_constraint const ON tabela.oid = const.confrelid
				INNER JOIN tmp_pg_attribute coluna ON coluna.attrelid = const.conrelid and const.conkey[1] = coluna.attnum
				INNER JOIN tmp_pg_class tabelaref ON const.conrelid = tabelaref.oid
				INNER JOIN tmp_pg_attribute colunaref ON colunaref.attrelid = const.conrelid and const.conkey[1] = colunaref.attnum
				INNER JOIN tmp_pg_namespace schemaref ON tabelaref.relnamespace = schemaref.oid

			WHERE LOWER(tabela.relname) = 'empresas' 
			  AND schema.nspname = 'ns'
			  AND tabelaref.relname <> 'usuarios'
			  AND tabelaref.relname IN 
			  ( 
			    SELECT cu.table_name
				FROM tmp_table_constraints pk
	      INNER JOIN tmp_referential_constraints fk ON pk.constraint_name = fk.unique_constraint_name
	      INNER JOIN tmp_key_column_usage cu ON fk.constraint_name = cu.constraint_name
				WHERE LOWER(pk.table_name) = 'empresas'
				ORDER BY 1 
	  ) 
			ORDER BY tabela.relname
		) 
		SELECT DISTINCT (TRIM(tabelafilha)::REGCLASS) FROM tabelasfilhasempresa
	) 
	INSERT INTO TMP_TABELAS_FILHAS_EMPRESA SELECT * FROM OIDS;

	--

	INSERT INTO TB_FK_ESTAB
	SELECT 
		DISTINCT coluna.attname AS campochave,
		objid, 
		CONCAT(nsp.nspname, '.', tabela.relname) AS tabela
	FROM tmp_viewdependency
		INNER JOIN tmp_pg_constraint const ON const.oid = objid
		INNER JOIN tmp_pg_attribute coluna ON coluna.attrelid = const.conrelid and const.conkey[1] = coluna.attnum
		INNER JOIN tmp_pg_class tabela ON tabela.oid = const.conrelid
		INNER JOIN tmp_pg_namespace nsp ON tabela.relnamespace = nsp.oid
	WHERE UPPER(object_identity) NOT LIKE '%PK_%' 
	AND UPPER(object_identity) NOT LIKE '%UK_%' 
	AND object_type IN ('TABLE CONSTRAINT')
	AND dependency_chain::CHARACTER VARYING LIKE '%'|| VAR_OID_NS_EMPRESAS::CHARACTER VARYING  ||'%';

	-- 

	SET SESSION "sistema.ativa_rastro" = 'FALSE';
	SET SESSION "sistema.excluindo_empresa" = 'TRUE';

	--

	DROP TABLE IF EXISTS tabela_filha_empresa;
	CREATE TEMP TABLE tabela_filha_empresa AS
	SELECT DISTINCT 
		const.conrelid,
		CONCAT(nsp.nspname, '.', tabela.relname)::CHARACTER VARYING tabela, 
		coluna.attname::CHARACTER VARYING campochave
	FROM tmp_pg_constraint const
		INNER JOIN tmp_pg_class tabela ON tabela.oid = const.conrelid
		INNER JOIN tmp_pg_attribute coluna ON coluna.attrelid = const.conrelid AND conkey[1] = coluna.attnum
		INNER JOIN tmp_pg_namespace nsp ON tabela.relnamespace = nsp.oid
		INNER JOIN TMP_TABELAS_FILHAS_EMPRESA oids ON oids.id = const.conrelid
	WHERE const.conrelid <> confrelid 
	  AND const.contype = 'f'
	  AND CONCAT(nsp.nspname, '.', tabela.relname)::CHARACTER VARYING NOT IN ('ns.usuarios', 'ns.empresas')
	ORDER BY const.conrelid DESC;
	
	FOR REG_TABELA_FILHA_EMPRESA IN (SELECT * FROM  tabela_filha_empresa) LOOP

		SELECT campochave 
		FROM TB_FK_ESTAB
		WHERE tabela = REG_TABELA_FILHA_EMPRESA.tabela 
		INTO REG_INFO_CAMPOS;

		IF REG_INFO_CAMPOS.campochave IS NULL THEN
			CONTINUE;
		END IF;

		RAISE NOTICE 'Tabela % sendo excluída...',REG_TABELA_FILHA_EMPRESA.tabela;

		PERFORM ns.delete_cascade_hard(REG_TABELA_FILHA_EMPRESA.tabela, REG_INFO_CAMPOS.campochave, a_empresas);

		RAISE NOTICE 'Tabela % excluída!',REG_TABELA_FILHA_EMPRESA.tabela;
		RAISE NOTICE '';

	END LOOP;

	SELECT array_to_string(array_agg('''' || valor::VARCHAR || '''::uuid'), ',') 
	INTO VAR_EMPRESAS_STR
	FROM UNNEST(a_empresas) AS valor;

	EXECUTE 'DELETE FROM NS.EMPRESAS WHERE EMPRESA = ANY(ARRAY[' || VAR_EMPRESAS_STR || ']);';

	SET SESSION "sistema.ativa_rastro" = 'TRUE';
	SET SESSION "sistema.excluindo_empresa" = 'FALSE';

    EXCEPTION

      WHEN OTHERS THEN
        SET SESSION "sistema.ativa_rastro" = 'TRUE';
        SET SESSION "sistema.excluindo_empresa" = 'FALSE';
        RAISE EXCEPTION 'Ocorreu um erro durante a exclusão das empresas: %', SQLERRM;

    END;	
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION ns.apagarempresa_hard(uuid[])
  OWNER TO group_nasajon;
