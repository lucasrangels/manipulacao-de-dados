TRUNCATE contabil.saldos;

INSERT INTO contabil.saldos(ano, mes, dia, totaldebito, totalcredito, totaldebitoantestransf, totalcreditoantestransf, data, conta, estabelecimento)
WITH saldos AS (
SELECT
	estabelecimentos.codigo estabelecimentocodigo,
	estabelecimentos.estabelecimento estabelecimento,
	contas.codigo contacodigo,
	contas.conta conta,
	lancamentos.data,
	lancamentos.ano,
	EXTRACT(MONTH FROM lancamentos.data) mes,
	EXTRACT(DAY FROM lancamentos.data) dia,
	SUM(lancamentos.valor) debito,
	0 credito
FROM contabil.contas
INNER JOIN contabil.contasanuais ON contas.conta = contasanuais.conta
JOIN contabil.lancamentos ON contasanuais.contaanual = lancamentos.contadebito
JOIN ns.estabelecimentos ON lancamentos.estabelecimento = estabelecimentos.estabelecimento
GROUP BY 
	estabelecimentos.codigo,
	estabelecimentos.estabelecimento,
	contas.codigo,
	contas.conta,
	lancamentos.data,
	lancamentos.ano,
	EXTRACT(MONTH FROM lancamentos.data),
	EXTRACT(DAY FROM lancamentos.data)

UNION ALL

SELECT
	estabelecimentos.codigo,
	estabelecimentos.estabelecimento,
	contas.codigo,
	contas.conta,
	lancamentos.data,
	lancamentos.ano,
	EXTRACT(MONTH FROM lancamentos.data),
	EXTRACT(DAY FROM lancamentos.data),
	0,
	SUM(lancamentos.valor)
FROM contabil.contas
INNER JOIN contabil.contasanuais ON contas.conta = contasanuais.conta
JOIN contabil.lancamentos ON contasanuais.contaanual = lancamentos.contacredito
JOIN ns.estabelecimentos ON lancamentos.estabelecimento = estabelecimentos.estabelecimento
GROUP BY 
	estabelecimentos.codigo,
	estabelecimentos.estabelecimento,
	contas.codigo,
	contas.conta,
	lancamentos.data,
	lancamentos.ano,
	EXTRACT(MONTH FROM lancamentos.data),
	EXTRACT(DAY FROM lancamentos.data)
)
SELECT ano, mes, dia, SUM(debito) debito, SUM(credito) credito, SUM(debito) debito, SUM(credito) credito, data, conta, estabelecimento
FROM saldos
GROUP BY ano, mes, dia, data, conta, estabelecimento
ORDER BY ano, mes, dia, data, conta, estabelecimento;