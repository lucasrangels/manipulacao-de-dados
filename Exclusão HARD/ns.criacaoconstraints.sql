-- DROP FUNCTION SELECT ns.criacaoconstraints();

CREATE OR REPLACE FUNCTION ns.criacaoconstraints()
  RETURNS void AS
$BODY$
DECLARE 
	REG_CONSULTAS RECORD;
BEGIN
    
    BEGIN
	
	RAISE NOTICE 'Criando constraints...';	
	FOR REG_CONSULTAS IN (SELECT * FROM criacao_constraints) LOOP
		RAISE NOTICE '%',REG_CONSULTAS;
		EXECUTE REG_CONSULTAS.consulta;
	END LOOP;
	RAISE NOTICE 'Constraints criadas!';

	RAISE NOTICE 'Criando indexes...';
	FOR REG_CONSULTAS IN (SELECT * FROM criacao_index) LOOP
		EXECUTE REG_CONSULTAS.consulta;
	END LOOP;
	RAISE NOTICE 'Indexes criados!';
	
	DROP TABLE IF EXISTS tmp_pg_class;
	DROP TABLE IF EXISTS tmp_pg_namespace;
	DROP TABLE IF EXISTS tmp_pg_index;
	DROP TABLE IF EXISTS tmp_pg_attribute;
	DROP TABLE IF EXISTS tmp_pg_constraint;
	DROP TABLE IF EXISTS tmp_table_constraints;
	DROP TABLE IF EXISTS tmp_referential_constraints;
	DROP TABLE IF EXISTS tmp_key_column_usage;
	DROP TABLE IF EXISTS tmp_viewdependency;
	DROP TABLE IF EXISTS criacao_constraints;
	DROP TABLE IF EXISTS criacao_index;
	DROP TABLE IF EXISTS exclusao_constraints;
	DROP TABLE IF EXISTS exclusao_index;
	
	SET session_replication_role = DEFAULT;

    EXCEPTION

      WHEN OTHERS THEN
        SET session_replication_role = DEFAULT;
        RAISE EXCEPTION 'Ocorreu um erro durante o processamento: %', SQLSTATE;

    END;	
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION ns.criacaoconstraints()
  OWNER TO group_nasajon;
