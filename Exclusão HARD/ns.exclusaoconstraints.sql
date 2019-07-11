-- Function: ns.apagarempresa(uuid[])

-- DROP FUNCTION ns.exclusaoconstraints();

CREATE OR REPLACE FUNCTION ns.exclusaoconstraints()
  RETURNS void AS
$BODY$
DECLARE 
	REG_CONSULTAS RECORD;
BEGIN

    BEGIN
	DROP TABLE IF EXISTS tmp_pg_class;
	CREATE TABLE tmp_pg_class AS SELECT oid,* FROM pg_class;

	DROP TABLE IF EXISTS tmp_pg_namespace;
	CREATE TABLE tmp_pg_namespace AS SELECT oid,* FROM pg_namespace;

	DROP TABLE IF EXISTS tmp_pg_index;
	CREATE TABLE tmp_pg_index AS SELECT * FROM pg_index;

	DROP TABLE IF EXISTS tmp_pg_attribute;
	CREATE TABLE tmp_pg_attribute AS SELECT * FROM pg_attribute;

	DROP TABLE IF EXISTS tmp_pg_constraint;
	CREATE TABLE tmp_pg_constraint AS SELECT oid,* FROM pg_constraint;

	DROP TABLE IF EXISTS tmp_table_constraints;
	CREATE TABLE tmp_table_constraints AS SELECT * FROM information_schema.table_constraints;

	DROP TABLE IF EXISTS tmp_referential_constraints;
	CREATE TABLE tmp_referential_constraints AS SELECT * FROM information_schema.referential_constraints;

	DROP TABLE IF EXISTS tmp_key_column_usage;
	CREATE TABLE tmp_key_column_usage AS SELECT * FROM information_schema.key_column_usage;
	
	DROP TABLE IF EXISTS tmp_viewdependency;
	CREATE TABLE tmp_viewdependency AS SELECT * FROM ns.viewdependency;

	DROP TABLE IF EXISTS criacao_constraints;
	CREATE TABLE criacao_constraints AS
	SELECT 'ALTER TABLE '||nspname||'."'||relname||'" ADD CONSTRAINT "'||conname||'" '|| pg_get_constraintdef(pg_constraint.oid) AS consulta
	FROM pg_constraint
	INNER JOIN pg_class ON conrelid=pg_class.oid
	INNER JOIN pg_namespace ON pg_namespace.oid=pg_class.relnamespace
	WHERE contype='f'
	ORDER BY CASE WHEN contype='f' THEN 0 ELSE 1 END DESC,contype DESC,nspname DESC,relname DESC,conname DESC;

	DROP TABLE IF EXISTS criacao_index;
	CREATE TABLE criacao_index AS
	SELECT idxs.indexdef AS consulta
	FROM pg_index idx
	INNER JOIN pg_class i ON i.oid = idx.indexrelid
	INNER JOIN pg_class t ON t.oid = idx.indrelid
	INNER JOIN pg_namespace s ON i.relnamespace = s.oid
	INNER JOIN pg_indexes idxs ON s.nspname || '."' || i.relname || '"' = idxs.schemaname || '."' || idxs.indexname || '"'
	WHERE s.nspname NOT IN ('pg_catalog', 'pg_toast')
	AND NOT idx.indisprimary
	AND NOT idx.indisunique;

	DROP TABLE IF EXISTS exclusao_constraints;
	CREATE TABLE exclusao_constraints AS
	SELECT 'ALTER TABLE '||nspname||'."'||relname||'" DROP CONSTRAINT "'||conname||'"' AS consulta
	FROM pg_constraint
	INNER JOIN pg_class ON conrelid=pg_class.oid
	INNER JOIN pg_namespace ON pg_namespace.oid=pg_class.relnamespace
	WHERE contype='f'
	ORDER BY CASE WHEN contype='f' THEN 0 ELSE 1 END,contype,nspname,relname,conname;

	DROP TABLE IF EXISTS exclusao_index;
	CREATE TABLE exclusao_index AS
	SELECT 'DROP INDEX ' || idxs.schemaname || '."' || idxs.indexname || '"' AS consulta
	FROM pg_index idx
	INNER JOIN pg_class i ON i.oid = idx.indexrelid
	INNER JOIN pg_class t ON t.oid = idx.indrelid
	INNER JOIN pg_namespace s ON i.relnamespace = s.oid
	INNER JOIN pg_indexes idxs ON s.nspname || '."' || i.relname || '"' = idxs.schemaname || '."' || idxs.indexname || '"'
	WHERE s.nspname NOT IN ('pg_catalog', 'pg_toast')
	AND NOT idx.indisprimary
	AND NOT idx.indisunique;

	SET session_replication_role = replica;

	RAISE NOTICE 'Excluindo indexes...';
	FOR REG_CONSULTAS IN (SELECT * FROM exclusao_index) LOOP
		EXECUTE REG_CONSULTAS.consulta;
	END LOOP;
	RAISE NOTICE 'Indexes excluídos!';

	RAISE NOTICE 'Excluindo constraints...';
	FOR REG_CONSULTAS IN (SELECT * FROM exclusao_constraints) LOOP
		EXECUTE REG_CONSULTAS.consulta;
	END LOOP;
	RAISE NOTICE 'Constraints excluídas!';

    EXCEPTION

      WHEN OTHERS THEN
	SET session_replication_role = DEFAULT;
        RAISE EXCEPTION 'Ocorreu um erro durante o processamento: %', SQLERRM;

    END;	
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION ns.exclusaoconstraints()
  OWNER TO group_nasajon;