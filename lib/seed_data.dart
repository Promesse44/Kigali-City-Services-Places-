import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

/// Seeds the Firestore 'services' collection with real Kigali City services.
/// All coordinates are within the Kigali bounds defined in LocationService:
/// North: -1.9200, South: -1.9700, East: 30.0200, West: 29.8300
class FirestoreSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> isAlreadySeeded() async {
    final snapshot = await _firestore.collection('services').limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<void> seedServices() async {
    final batch = _firestore.batch();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'seed-data';

    for (final service in _kigaliServices) {
      final docRef = _firestore.collection('services').doc();
      final serviceData = Map<String, dynamic>.from(service);
      serviceData['id'] = docRef.id;
      serviceData['createdBy'] = currentUserId;
      serviceData['timestamp'] = Timestamp.now();
      batch.set(docRef, serviceData);
    }

    await batch.commit();
    developer.log('Seeded ${_kigaliServices.length} services into Firestore');
  }

  static const List<Map<String, dynamic>> _kigaliServices = [
    // ===== HOSPITALS =====
    {
      'name': 'King Faisal Hospital',
      'category': 'Hospital',
      'latitude': -1.9540,
      'longitude': 29.8810,
      'phone': '+250 252 582 421',
      'website': 'https://kfrh.rw',
      'description':
          'King Faisal Hospital is a leading referral and teaching hospital in Kigali, offering specialized medical services including surgery, internal medicine, and emergency care.',
    },
    {
      'name': 'CHUK - University Teaching Hospital',
      'category': 'Hospital',
      'latitude': -1.9480,
      'longitude': 29.8700,
      'phone': '+250 252 575 171',
      'website': 'https://chuk.rw',
      'description':
          'Centre Hospitalier Universitaire de Kigali (CHUK) is one of the largest public referral hospitals in Rwanda, affiliated with the University of Rwanda.',
    },
    {
      'name': 'Rwanda Military Hospital',
      'category': 'Hospital',
      'latitude': -1.9450,
      'longitude': 29.8760,
      'phone': '+250 252 587 602',
      'website': null,
      'description':
          'Rwanda Military Hospital (Kanombe) provides medical services to military personnel and civilians in Kigali.',
    },
    {
      'name': 'Kibagabaga Hospital',
      'category': 'Hospital',
      'latitude': -1.9350,
      'longitude': 29.8920,
      'phone': '+250 252 585 742',
      'website': null,
      'description':
          'Kibagabaga Hospital is a district hospital in Gasabo serving the northern Kigali community with general medical services.',
    },
    {
      'name': 'Muhima Hospital',
      'category': 'Hospital',
      'latitude': -1.9520,
      'longitude': 29.8580,
      'phone': '+250 252 572 590',
      'website': null,
      'description':
          'Muhima Hospital is a district hospital located in Nyarugenge district, known for maternity and general healthcare services.',
    },
    {
      'name': 'Masaka Hospital',
      'category': 'Hospital',
      'latitude': -1.9650,
      'longitude': 29.8450,
      'phone': '+250 252 562 310',
      'website': null,
      'description':
          'Masaka Hospital serves the Kicukiro district area providing general medical care and outpatient services.',
    },

    // ===== PHARMACIES =====
    {
      'name': 'Pharmacy Plus Kigali',
      'category': 'Pharmacy',
      'latitude': -1.9510,
      'longitude': 29.8720,
      'phone': '+250 788 300 200',
      'website': null,
      'description':
          'A well-stocked pharmacy in central Kigali offering prescription and over-the-counter medications.',
    },
    {
      'name': 'Pharmacie Conseil Remera',
      'category': 'Pharmacy',
      'latitude': -1.9560,
      'longitude': 29.8950,
      'phone': '+250 788 456 123',
      'website': null,
      'description':
          'Located in Remera, this pharmacy provides pharmaceutical products and health consultations.',
    },
    {
      'name': 'Kigali Health Pharmacy',
      'category': 'Pharmacy',
      'latitude': -1.9480,
      'longitude': 29.8650,
      'phone': '+250 788 112 233',
      'website': null,
      'description':
          'Kigali Health Pharmacy offers a wide range of medicines, vitamins, and medical supplies near the city center.',
    },
    {
      'name': 'La Pharmacie du Peuple',
      'category': 'Pharmacy',
      'latitude': -1.9570,
      'longitude': 29.8680,
      'phone': '+250 788 654 321',
      'website': null,
      'description':
          'An affordable pharmacy in Nyarugenge providing essential medications and health products.',
    },

    // ===== SCHOOLS =====
    {
      'name': 'Green Hills Academy',
      'category': 'School',
      'latitude': -1.9420,
      'longitude': 29.8830,
      'phone': '+250 252 585 927',
      'website': 'https://greenhillsacademy.rw',
      'description':
          'Green Hills Academy is a prestigious international school offering IB curriculum from preschool through high school.',
    },
    {
      'name': 'Kigali International Community School',
      'category': 'School',
      'latitude': -1.9380,
      'longitude': 29.8900,
      'phone': '+250 252 583 781',
      'website': 'https://kfrh.rw',
      'description':
          'KICS is an international school serving the expatriate and local community with American curriculum.',
    },
    {
      'name': 'Lycee de Kigali',
      'category': 'School',
      'latitude': -1.9530,
      'longitude': 29.8770,
      'phone': '+250 252 576 020',
      'website': null,
      'description':
          'Lycee de Kigali is one of the oldest and most reputable secondary schools in Rwanda.',
    },
    {
      'name': 'Ecole Belge de Kigali',
      'category': 'School',
      'latitude': -1.9460,
      'longitude': 29.8630,
      'phone': '+250 252 574 412',
      'website': null,
      'description':
          'The Belgian School of Kigali offers bilingual education following the Belgian curriculum.',
    },
    {
      'name': 'Groupe Scolaire Officiel de Butamwa',
      'category': 'School',
      'latitude': -1.9600,
      'longitude': 29.8400,
      'phone': '+250 788 321 654',
      'website': null,
      'description':
          'A public primary and secondary school serving the Kicukiro community.',
    },

    // ===== MARKETS =====
    {
      'name': 'Kimironko Market',
      'category': 'Market',
      'latitude': -1.9400,
      'longitude': 29.9000,
      'phone': null,
      'website': null,
      'description':
          'Kimironko Market is one of the largest and most popular markets in Kigali, offering fresh produce, textiles, crafts, and household goods.',
    },
    {
      'name': 'Kigali City Market (Caplaki)',
      'category': 'Market',
      'latitude': -1.9500,
      'longitude': 29.8750,
      'phone': null,
      'website': null,
      'description':
          'Caplaki Crafts Village is a market specializing in Rwandan arts, crafts, and souvenirs located near the city center.',
    },
    {
      'name': 'Nyabugogo Market',
      'category': 'Market',
      'latitude': -1.9430,
      'longitude': 29.8500,
      'phone': null,
      'website': null,
      'description':
          'Nyabugogo Market is a bustling wholesale and retail market located near the main bus terminal, offering fresh produce and goods.',
    },
    {
      'name': 'Kicukiro Market',
      'category': 'Market',
      'latitude': -1.9620,
      'longitude': 29.8600,
      'phone': null,
      'website': null,
      'description':
          'A local market in Kicukiro district providing affordable fresh vegetables, fruits, and everyday essentials.',
    },

    // ===== GOVERNMENT OFFICES =====
    {
      'name': 'Kigali City Hall',
      'category': 'Government',
      'latitude': -1.9505,
      'longitude': 29.8739,
      'phone': '+250 252 581 862',
      'website': 'https://kigalicity.gov.rw',
      'description':
          'Kigali City Hall is the main administrative office of the City of Kigali, handling urban planning, permits, and city governance.',
    },
    {
      'name': 'Gasabo District Office',
      'category': 'Government',
      'latitude': -1.9370,
      'longitude': 29.8870,
      'phone': '+250 252 585 110',
      'website': null,
      'description':
          'The Gasabo District office handles local government services for the Gasabo district of Kigali.',
    },
    {
      'name': 'Kicukiro District Office',
      'category': 'Government',
      'latitude': -1.9640,
      'longitude': 29.8550,
      'phone': '+250 252 562 415',
      'website': null,
      'description':
          'The Kicukiro District office manages administrative services and community affairs for Kicukiro.',
    },
    {
      'name': 'Nyarugenge District Office',
      'category': 'Government',
      'latitude': -1.9545,
      'longitude': 29.8700,
      'phone': '+250 252 573 830',
      'website': null,
      'description':
          'The Nyarugenge District office provides government services for the central Kigali district.',
    },
    {
      'name': 'Rwanda Revenue Authority (RRA)',
      'category': 'Government',
      'latitude': -1.9490,
      'longitude': 29.8780,
      'phone': '+250 252 595 500',
      'website': 'https://rra.gov.rw',
      'description':
          'Rwanda Revenue Authority headquarters handles tax collection, customs, and revenue services.',
    },
    {
      'name': 'Immigration & Emigration Office',
      'category': 'Government',
      'latitude': -1.9530,
      'longitude': 29.8850,
      'phone': '+250 252 582 907',
      'website': 'https://migration.gov.rw',
      'description':
          'The Directorate General of Immigration and Emigration handles passports, visas, and residence permits.',
    },

    // ===== BANKS =====
    {
      'name': 'Bank of Kigali - Head Office',
      'category': 'Bank',
      'latitude': -1.9515,
      'longitude': 29.8755,
      'phone': '+250 252 595 900',
      'website': 'https://bk.rw',
      'description':
          'Bank of Kigali is the largest commercial bank in Rwanda, offering savings, loans, and digital banking services.',
    },
    {
      'name': 'Equity Bank Kigali',
      'category': 'Bank',
      'latitude': -1.9525,
      'longitude': 29.8710,
      'phone': '+250 788 190 000',
      'website': 'https://equitybankgroup.com',
      'description':
          'Equity Bank provides personal and business banking services including accounts, loans, and mobile money.',
    },
    {
      'name': 'I&M Bank Kigali',
      'category': 'Bank',
      'latitude': -1.9495,
      'longitude': 29.8735,
      'phone': '+250 252 599 100',
      'website': 'https://imbank.com',
      'description':
          'I&M Bank Rwanda offers commercial banking services, trade finance, and treasury services.',
    },

    // ===== RELIGIOUS =====
    {
      'name': 'Kigali Catholic Cathedral (St. Michel)',
      'category': 'Religious',
      'latitude': -1.9530,
      'longitude': 29.8690,
      'phone': null,
      'website': null,
      'description':
          'Saint Michel Cathedral is the main Catholic cathedral in Kigali, a historic landmark in the Nyarugenge area.',
    },
    {
      'name': 'Remera Mosque',
      'category': 'Religious',
      'latitude': -1.9555,
      'longitude': 29.8940,
      'phone': null,
      'website': null,
      'description':
          'A prominent mosque in the Remera neighborhood serving the Muslim community of Kigali.',
    },
  ];
}
