UPDATE ns.estabelecimentos SET
    inicioexercicio = (SELECT (MIN(ano)::VARCHAR || '-01-01')::DATE FROM contabil.lancamentos WHERE estabelecimento = estabelecimentos.estabelecimento);

UPDATE ns.empresas SET
    inicioexercicio = (SELECT MIN(inicioexercicio) FROM ns.estabelecimentos WHERE inicioexercicio IS NOT NULL AND empresa = empresas.empresa);