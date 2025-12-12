import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/service.dart';

class ServiceCatalogService {
  ServiceCatalogService._();

  static final ServiceCatalogService instance = ServiceCatalogService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Local, in-memory categories used for main page, category page and search.
  // Providers and services are still loaded from Firestore.
  static const List<CategoryModel> _localCategories = [
    CategoryModel(
      id: 'cleaner',
      name: 'Cleaner',
      iconUrl: 'assets/categories/cleaning.png',
    ),
    CategoryModel(
      id: 'ac_repair',
      name: 'AC Repair',
      iconUrl: 'assets/categories/Ac_Repair.png',
    ),
    CategoryModel(
      id: 'plumber',
      name: 'Plumber',
      iconUrl: 'assets/categories/plumber.png',
    ),
    CategoryModel(
      id: 'electrician',
      name: 'Electrician',
      iconUrl: 'assets/categories/electrician.png',
    ),
    CategoryModel(
      id: 'carpenter',
      name: 'Carpenter',
      iconUrl: 'assets/categories/carpentry.png',
    ),
    CategoryModel(
      id: 'painter',
      name: 'Painter',
      iconUrl: 'assets/categories/painter.png',
    ),
    CategoryModel(
      id: 'barber',
      name: 'Barber',
      iconUrl: 'assets/categories/barber.png',
    ),
  ];

  CollectionReference<Map<String, dynamic>> get _servicesCol =>
      _db.collection('services');

  Stream<List<CategoryModel>> watchCategories() {
    // Categories are local/static. Expose them as a one-shot stream so existing
    // StreamBuilder-based UIs keep working without hitting Firestore.
    final active =
        _localCategories.where((c) => c.isActive).toList(growable: false);
    return Stream.value(active);
  }

  Stream<List<ServiceModel>> watchServicesForCategory(String categoryId) {
    return _servicesCol
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ServiceModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<ServiceModel?> getService(String id) async {
    final doc = await _servicesCol.doc(id).get();
    if (!doc.exists) return null;
    return ServiceModel.fromMap(doc.id, doc.data()!);
  }
}
