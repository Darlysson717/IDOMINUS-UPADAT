
import 'package:flutter/material.dart';

class FiltroAvancado extends StatefulWidget {
	final void Function(Map<String, String?> filtros) onAplicar;
	final VoidCallback onLimpar;

	const FiltroAvancado({
		Key? key,
		required this.onAplicar,
		required this.onLimpar,
	}) : super(key: key);

	@override
	State<FiltroAvancado> createState() => _FiltroAvancadoState();
}

class _FiltroAvancadoState extends State<FiltroAvancado> {

		String? _marca;
		String? _modelo;
		int? _anoMin;
		int? _anoMax;
		double? _precoMin;
		double? _precoMax;
		int? _kmMin;
		int? _kmMax;
		String? _combustivel;
		String? _cambio;
		String? _motorizacao;
		String? _cor;
		int? _numPortas;
		String? _condicao;

		String? _carroceria;

		String? _direcao;

		String? _farois;

		String? _situacaoVeiculo;

		final List<String> _marcas = const [

    'Chevrolet','Volkswagen','Fiat','Toyota','Hyundai','Jeep','Renault','Honda','Nissan','Caoa Chery',

    'Peugeot','Citroën','Mitsubishi','BMW','Mercedes-Benz','Audi','Volvo','Land Rover','Suzuki','Kia',

    'Ford','JAC','RAM','BYD','GWM (Haval)','Mini','Porsche','Jaguar','Lexus','Ferrari','Maserati','Dodge','Subaru'

  ];
		final Map<String, List<String>> _modelosPorMarca = {
			'Toyota': ['Corolla', 'Hilux', 'Etios'],
			'Fiat': ['Uno', 'Argo', 'Toro'],
			'Ford': ['Fiesta', 'Ka', 'EcoSport'],
			'Chevrolet': ['Onix', 'Prisma', 'S10'],
			'Volkswagen': ['Gol', 'Polo', 'Virtus'],
			'Honda': ['Civic', 'Fit', 'HR-V'],
			'Hyundai': ['HB20', 'Creta'],
			'Renault': ['Sandero', 'Duster'],
			'Nissan': ['Kicks', 'Versa'],
			'Jeep': ['Renegade', 'Compass'],
		};
		final List<String> _combustiveis = ['Gasolina', 'Etanol', 'Flex', 'Diesel', 'Elétrico', 'Híbrido'];
		final List<String> _cambios = ['Manual', 'Automático', 'CVT'];
		final List<String> _motorizacoes = const [

    '1.0','1.0 Turbo','1.3','1.4','1.4 Turbo','1.5','1.6','1.6 16V','1.8','2.0','2.0 Turbo','2.2','2.4','V6','V8','Elétrico','Híbrido','Outro'

  ];
		final List<String> _cores = ['Preto', 'Branco', 'Prata', 'Cinza', 'Vermelho', 'Azul', 'Verde', 'Amarelo', 'Outro'];
		final List<int> _portas = [2, 3, 4, 5];
		final List<String> _condicoes = ['Novo', 'Usado', 'Seminovo'];

		final List<String> _carrocerias = const [

    'Hatch','Sedan','SUV','Picape','Perua','Cupê','Conversível','Minivan','Utilitário','Outro'

  ];

		final List<String> _direcoes = const ['Elétrica', 'Hidráulica', 'Mecânica'];

		final List<String> _faroisOpcoes = const ['LED', 'Halógeno', 'Xenon'];

		final List<String> _situacoesVeiculo = const ['Em dia', 'Financiado', 'Multado', 'Outro'];


		void _aplicar() {
			widget.onAplicar({
				'marca': _marca,
				'modelo': _modelo,
				'anoMin': _anoMin?.toString(),
				'anoMax': _anoMax?.toString(),
				'precoMin': _precoMin?.toString(),
				'precoMax': _precoMax?.toString(),
				'kmMin': _kmMin?.toString(),
				'kmMax': _kmMax?.toString(),
				'cor': _cor,
				'combustivel': _combustivel,
				'cambio': _cambio,
				'motorizacao': _motorizacao,
				'numPortas': _numPortas?.toString(),
				'condicao': _condicao,
			});
		}

		void _limpar() {
			setState(() {
				_marca = null;
				_modelo = null;
				_anoMin = null;
				_anoMax = null;
				_precoMin = null;
				_precoMax = null;
				_kmMin = null;
				_kmMax = null;
				_cor = null;
				_combustivel = null;
				_cambio = null;
				_motorizacao = null;
				_numPortas = null;
				_condicao = null;
			});
			widget.onLimpar();
		}



		@override
		Widget build(BuildContext context) {
			final modelos = _marca != null ? _modelosPorMarca[_marca!] ?? [] : <String>[];
			return Padding(
				padding: EdgeInsets.only(
					left: 24, right: 24,
					top: 24,
					bottom: MediaQuery.of(context).viewInsets.bottom + 24,
				),
				child: SingleChildScrollView(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: [
									const Text('Filtros avançados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
									IconButton(
										icon: const Icon(Icons.close),
										onPressed: () => Navigator.pop(context),
									),
								],
							),
							const SizedBox(height: 12),
							DropdownButtonFormField<String>(
								value: _marca,
								items: _marcas.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
								onChanged: (v) => setState(() {
									_marca = v;
									_modelo = null;
								}),
								decoration: const InputDecoration(labelText: 'Marca'),
							),
							DropdownButtonFormField<String>(
								value: _modelo,
								items: modelos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
								onChanged: (v) => setState(() => _modelo = v),
								decoration: const InputDecoration(labelText: 'Modelo'),
							),
							Row(
								children: [
									Expanded(
										child: TextFormField(
											initialValue: _anoMin?.toString(),
											decoration: const InputDecoration(labelText: 'Ano mín.'),
											keyboardType: TextInputType.number,
											onChanged: (v) => setState(() => _anoMin = int.tryParse(v)),
										),
									),
									const SizedBox(width: 12),
									Expanded(
										child: TextFormField(
											initialValue: _anoMax?.toString(),
											decoration: const InputDecoration(labelText: 'Ano máx.'),
											keyboardType: TextInputType.number,
											onChanged: (v) => setState(() => _anoMax = int.tryParse(v)),
										),
									),
								],
							),
							Row(
								children: [
									Expanded(
										child: TextFormField(
											initialValue: _precoMin?.toString(),
											decoration: const InputDecoration(labelText: 'Preço mín.'),
											keyboardType: TextInputType.number,
											onChanged: (v) => setState(() => _precoMin = double.tryParse(v.replaceAll(',', '.'))),
										),
									),
									const SizedBox(width: 12),
									Expanded(
										child: TextFormField(
											initialValue: _precoMax?.toString(),
											decoration: const InputDecoration(labelText: 'Preço máx.'),
											keyboardType: TextInputType.number,
											onChanged: (v) => setState(() => _precoMax = double.tryParse(v.replaceAll(',', '.'))),
										),
									),
								],
							),
							Row(
								children: [
									Expanded(
										child: TextFormField(
											initialValue: _kmMin?.toString(),
											decoration: const InputDecoration(labelText: 'Km mín.'),
											keyboardType: TextInputType.number,
											onChanged: (v) => setState(() => _kmMin = int.tryParse(v)),
										),
									),
									const SizedBox(width: 12),
									Expanded(
										child: TextFormField(
											initialValue: _kmMax?.toString(),
											decoration: const InputDecoration(labelText: 'Km máx.'),
											keyboardType: TextInputType.number,
											onChanged: (v) => setState(() => _kmMax = int.tryParse(v)),
										),
									),
								],
							),
							DropdownButtonFormField<String>(
								value: _combustivel,
								items: _combustiveis.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
								onChanged: (v) => setState(() => _combustivel = v),
								decoration: const InputDecoration(labelText: 'Combustível'),
							),
							DropdownButtonFormField<String>(
								value: _cambio,
								items: _cambios.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
								onChanged: (v) => setState(() => _cambio = v),
								decoration: const InputDecoration(labelText: 'Câmbio'),
							),
							DropdownButtonFormField<String>(
								value: _motorizacao,
								items: _motorizacoes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
								onChanged: (v) => setState(() => _motorizacao = v),
								decoration: const InputDecoration(labelText: 'Motorização'),
							),
							DropdownButtonFormField<String>(
								value: _cor,
								items: _cores.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
								onChanged: (v) => setState(() => _cor = v),
								decoration: const InputDecoration(labelText: 'Cor'),
							),
							DropdownButtonFormField<int>(
								value: _numPortas,
								items: _portas.map((p) => DropdownMenuItem(value: p, child: Text(p.toString()))).toList(),
								onChanged: (v) => setState(() => _numPortas = v),
								decoration: const InputDecoration(labelText: 'Nº de portas'),
							),
							DropdownButtonFormField<String>(
								value: _condicao,
								items: _condicoes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
								onChanged: (v) => setState(() => _condicao = v),
								decoration: const InputDecoration(labelText: 'Condição'),
							),
							const SizedBox(height: 20),
							ElevatedButton(
								onPressed: () {
									_aplicar();
									Navigator.pop(context);
								},
								style: ElevatedButton.styleFrom(
									backgroundColor: Theme.of(context).brightness == Brightness.dark 
									  ? Colors.white24 
									  : Colors.deepPurple,
									foregroundColor: Theme.of(context).brightness == Brightness.dark 
									  ? Colors.white 
									  : Colors.white,
									padding: const EdgeInsets.symmetric(vertical: 14),
								),
								child: const Text('Aplicar Filtros'),
							),
							TextButton(
								onPressed: () {
									_limpar();
									Navigator.pop(context);
								},
								child: const Text('Limpar Filtros'),
							),
						],
					),
				),
			);
		}
}
