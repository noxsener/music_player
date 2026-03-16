import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class RichResultConfigDialog extends StatefulWidget {
  final String type;
  final String? initialData;

  const RichResultConfigDialog({super.key, required this.type, this.initialData});

  @override
  State<RichResultConfigDialog> createState() => _RichResultConfigDialogState();
}

class _RichResultConfigDialogState extends State<RichResultConfigDialog> {
  final Map<String, dynamic> _formData = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      try {
        _formData.addAll(jsonDecode(widget.initialData!));
      } catch (e) {
        debugPrint("Veri parse hatası: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("${widget.type} Detaylarını Yapılandır"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildFieldsForType(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.pop(context, jsonEncode(_formData));
            }
          },
          child: const Text("Kaydet"),
        ),
      ],
    );
  }

  final Map<String, String> localBusinessTypeList = {
    'Store': 'Mağaza / Dükkan',
    'AnimalShelter': 'Hayvan Barınağı',
    'ArchiveOrganization': 'Arşiv Merkezi',
    'AutomotiveBusiness': 'Otomotiv İşletmesi',
    'ChildCare': 'Çocuk Bakım Merkezi',
    'Dentist': 'Diş Hekimi',
    'DryCleaningOrLaundry': 'Kuru Temizleme / Çamaşırhane',
    'EmergencyService': 'Acil Servis',
    'EmploymentAgency': 'İş Kurumu / İnsan Kaynakları',
    'EntertainmentBusiness': 'Eğlence İşletmesi',
    'FinancialService': 'Finansal Hizmetler',
    'FoodEstablishment': 'Gıda / Restoran İşletmesi',
    'GovernmentOffice': 'Kamu Kurumu / Devlet Dairesi',
    'HealthAndBeautyBusiness': 'Sağlık ve Güzellik Merkezi',
    'HomeAndConstructionBusiness': 'Ev ve İnşaat İşletmesi',
    'InternetCafe': 'İnternet Kafe',
    'LegalService': 'Hukuk Hizmetleri / Avukatlık',
    'Library': 'Kütüphane',
    'LodgingBusiness': 'Konaklama İşletmesi (Otel vb.)',
    'MedicalBusiness': 'Tıbbi İşletme / Klinik',
    'ProfessionalService': 'Profesyonel Hizmetler',
    'RadioStation': 'Radyo İstasyonu',
    'RealEstateAgent': 'Emlak Ofisi',
    'RecyclingCenter': 'Geri Dönüşüm Merkezi',
    'SelfStorage': 'Kişisel Depolama Alanı',
    'ShoppingCenter': 'Alışveriş Merkezi',
    'SportsActivityLocation': 'Spor Etkinlik Alanı / Salonu',
    'TelevisionStation': 'Televizyon İstasyonu',
    'TouristInformationCenter': 'Turizm Danışma Merkezi',
    'TravelAgency': 'Seyahat Acentesi',
  };

  final Map<String, String> softwareTypeList = {
    "MobileApplication" : "Mobil Uygulama",
    "OperatingSystem" : "İşletim Sistemi",
    "RuntimePlatform" : "Runtime Platform",
    "VideoGame" : "Video Oyunu",
    "WebApplication" : "Web Uygulaması",
  };


  List<Widget> _buildFieldsForType() {
    switch (widget.type) {
      case 'LOCAL_BUSINESS':
        return [
          _buildDropdownField("@type", "İşletme Türü", localBusinessTypeList,'Store',"İşletme Türünü Seçin"),
          _buildTextField("name", "İşletme Adı"),
          _buildTextField("telephone", "Telefon"),
          _buildTextField("priceRange", "Fiyat Aralığı (Örn: \$\$)"),
          _buildTextField("url", "Web Sayfası"),
          const Divider(),
          const Text("İşletme Türünü Seçin"),

          const Divider(),
          const Text("Adres Bilgileri", style: TextStyle(fontWeight: FontWeight.bold)),
          _buildSubTextField("address", "streetAddress", "Sokak/Cadde"),
          _buildSubTextField("address", "addressLocality", "Şehir/İlçe"),
          _buildSubTextField("address", "addressRegion", "Bölge/Eyalet"),
          _buildSubTextField("address","addressCountry", "Ülke Kodu (TR)"),
          _buildSubTextField("address", "postalCode", "Posta Kodu"),
        ];
      case 'ORGANIZATION':
        return [
          _buildTextField("name", "Kuruluş Adı"),
          _buildTextField("description", "Açıklama"),
          _buildTextField("url", "Resmi Web Sitesi"),
          _buildTextField("logo", "Logo URL"),
          _buildTextField("email", "EMail"),
          _buildTextField("telephone", "Telefon"),
          _buildSubTextField("address","streetAddress", "Adres"),
          _buildSubTextField("address","addressLocality", "Şehir"),
          _buildSubTextField("address","addressCountry", "Ülke Kodu (TR)"),
          _buildSubTextField("address","postalCode", "Posta Kodu"),
          const Text("Sosyal Medya (Virgülle ayırın)"),
          _buildListField("sameAs", "Profil Linkleri"),
        ];
      case 'SOFTWARE':
        return [
          _buildTextField("name", "Uygulama Adı"),
          _buildTextField("operatingSystem", "İşletim Sistemi (Örn: Android, iOS)"),
          _buildTextField("applicationCategory", "Kategori (Örn: BusinessApplication)"),
          _buildDropdownField("applicationCategory", "Uygulama Türü", softwareTypeList,'MobileApplication',"Uygulama Türünü Seçin"),
          _buildSubTextField("offers", "price", "Fiyat (Zorunlu, Ücretsiz ise sıfır girin)"),
          _buildSubTextField("offers", "priceCurrency", "Para Birimi (Zorunlu USD/TRY)"),
          _buildSubTextField("aggregateRating", "ratingValue", "Store puanı (Zorunlu,1-5 ve arası değerler)"),
          _buildSubTextField("aggregateRating", "ratingCount", "Store puanlama sayısı (Zorunlu,Sayısal değer)"),
        ];
      case 'EVENT':
        return [
          _buildTextField("name", "Etkinlik Adı"),
          _buildTextField("startDate", "Başlangıç (ISO format: 2025-05-21T19:00:00)"),
          _buildTextField("endDate", "Bitiş"),
          _buildSubTextField("location", "name", "Mekan Adı"),
        ];
      default:
        return [const Text("Bu tip için ek yapılandırma gerekmiyor.")];
    }
  }



  Widget _buildTextField(String key, String label) {
    return TextFormField(
      initialValue: _formData[key]?.toString() ?? '',
      decoration: InputDecoration(labelText: label),
      onSaved: (val) => _formData[key] = val,
    );
  }

  Widget _buildSubTextField(String parentKey, String key, String label) {
    if (_formData[parentKey] == null) _formData[parentKey] = {};
    return TextFormField(
      initialValue: _formData[parentKey][key]?.toString() ?? '',
      decoration: InputDecoration(labelText: label),
      onSaved: (val) => _formData[parentKey][key] = val,
    );
  }

  Widget _buildListField(String key, String label) {
    return TextFormField(
      initialValue: (_formData[key] as List?)?.join(", ") ?? '',
      decoration: InputDecoration(labelText: label, hintText: "url1, url2"),
      onSaved: (val) {
        if (val != null && val.isNotEmpty) {
          _formData[key] = val.split(",").map((e) => e.trim()).toList();
        }
      },
    );
  }

  Widget _buildDropdownField(String key, String label, Map<String, String> items, String defaultValue, String description) {
    String? currentValue = _formData[key]?.toString();

    if (currentValue != null && !items.containsKey(currentValue)) {
      currentValue = defaultValue;
    }

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(labelText: label),
      items: items.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _formData[key] = val;
        });
      },
      onSaved: (val) => _formData[key] = val,
      validator: (val) => val == null ? description : null,
    );
  }
}