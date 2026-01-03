import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'payment_page.dart';

class CreateAdPage extends StatefulWidget {
  const CreateAdPage({super.key});

  @override
  State<CreateAdPage> createState() => _CreateAdPageState();
}

class _CreateAdPageState extends State<CreateAdPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedAdType = 'basico';
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _creativeTextController = TextEditingController();
  File? _selectedImage;

  final List<Map<String, dynamic>> _adTypes = [
    {
      'value': 'basico',
      'label': 'Básico - Banner rotativo local',
      'description': 'Seu anúncio aparece em banners rotativos na região',
      'price': 'R\$ 20/mês',
    },
    {
      'value': 'destaque',
      'label': 'Destaque - Card patrocinado',
      'description': 'Seu anúncio aparece como card especial nos resultados',
      'price': 'R\$ 50/mês',
    },
    {
      'value': 'premium',
      'label': 'Premium - Prioridade + topo',
      'description': 'Maior visibilidade com prioridade máxima',
      'price': 'R\$ 75/mês',
    },
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _categoryController.dispose();
    _cityController.dispose();
    _whatsappController.dispose();
    _websiteController.dispose();
    _creativeTextController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permissão de localização negada'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissões de localização permanentemente negadas. Vá nas configurações para habilitar.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Obter posição atual
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Converter coordenadas para endereço
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String city = place.subAdministrativeArea ?? place.locality ?? place.administrativeArea ?? '';

        if (city.isNotEmpty) {
          setState(() {
            _cityController.text = city;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cidade detectada: $city'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Não foi possível detectar a cidade'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao obter localização: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Coletar dados do anúncio
      final adData = {
        'businessName': _businessNameController.text,
        'category': _categoryController.text,
        'city': _cityController.text,
        'whatsapp': _whatsappController.text,
        'website': _websiteController.text,
        'creativeText': _creativeTextController.text,
        'image': _selectedImage,
      };

      // Obter preço do plano selecionado
      final selectedPlanData = _adTypes.firstWhere(
        (plan) => plan['value'] == _selectedAdType,
      );

      // Navegar para a tela de pagamento
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            selectedPlan: _selectedAdType,
            planPrice: selectedPlanData['price'],
            adData: adData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar anúncio'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Passo 1: Escolher tipo de anúncio
              _buildStepHeader('1️⃣', 'Escolha o tipo de anúncio'),
              const SizedBox(height: 16),
              ..._adTypes.map((type) => _buildAdTypeOption(type)),
              const SizedBox(height: 32),

              // Passo 2: Preencher informações
              _buildStepHeader('2️⃣', 'Informações do negócio'),
              const SizedBox(height: 16),

              // Nome do negócio
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do negócio (opcional)',
                  hintText: 'Ex: Oficina do João',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),

              // Categoria
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoria (opcional)',
                  hintText: 'Ex: Oficina mecânica, Lava-jato, etc.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),

              // Cidade
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Cidade (opcional)',
                        hintText: 'Ex: São Paulo - SP',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Usar localização atual',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFF667EEA),
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // WhatsApp
              TextFormField(
                controller: _whatsappController,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp (opcional)',
                  hintText: '(11) 99999-9999',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Website (opcional)
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website (opcional)',
                  hintText: 'www.seusite.com.br',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.web),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 32),

              // Passo 3: Criativo
              _buildStepHeader('3️⃣', 'Criativo do anúncio'),
              const SizedBox(height: 16),

              // Selecionar imagem
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Selecione uma imagem',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('Escolher imagem'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 16),

              // Texto do anúncio
              TextFormField(
                controller: _creativeTextController,
                decoration: const InputDecoration(
                  labelText: 'Texto do anúncio (opcional)',
                  hintText: 'Descreva seu negócio e serviços oferecidos...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // Botão de envio
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: const Color(0xFF667EEA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Criar anúncio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader(String emoji, String title) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAdTypeOption(Map<String, dynamic> type) {
    final isSelected = _selectedAdType == type['value'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAdType = type['value'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<String>(
                value: type['value'],
                groupValue: _selectedAdType,
                onChanged: (value) {
                  setState(() {
                    _selectedAdType = value!;
                  });
                },
                activeColor: const Color(0xFF667EEA),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type['label'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        type['price'],
                        style: const TextStyle(
                          color: Color(0xFF667EEA),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}