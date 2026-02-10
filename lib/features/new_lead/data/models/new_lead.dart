// Data model for the Essentials New Lead feature.
// Contains all fields from the New Lead PDF template.

/// Size/Credit Score rating
enum Rating { a, b, c }

/// Customer Type
enum CustomerType { trader, manufacturer }

/// Product priority selection (null = not selected)
class ProductSelection {
  final bool selected;
  final Rating? priority;

  const ProductSelection({this.selected = false, this.priority});

  ProductSelection copyWith({bool? selected, Rating? priority}) {
    return ProductSelection(
      selected: selected ?? this.selected,
      priority: priority ?? this.priority,
    );
  }
}

/// Main New Lead data model
class NewLead {
  // Account Manager section
  final String accountManager;

  // Customer General Info section
  final String accountName;
  final String mainContactName;
  final String city;
  final String zone;
  final Rating? size;
  final Rating? creditScoreAssessment;
  final CustomerType? customerType;
  final String phoneNo;
  final String addressGpsLocation;

  // Customer's Products section
  final ProductSelection sewingThread;
  final ProductSelection jeansSewingThread;
  final ProductSelection polyesterEmbroidery;
  final ProductSelection rayon;
  final ProductSelection nonWoven;
  final ProductSelection spray;
  final ProductSelection metallicYarn;
  final ProductSelection rubberThread;
  final ProductSelection yarn;
  final ProductSelection fabric;

  const NewLead({
    required this.accountManager,
    required this.accountName,
    required this.mainContactName,
    required this.city,
    required this.zone,
    this.size,
    this.creditScoreAssessment,
    this.customerType,
    required this.phoneNo,
    required this.addressGpsLocation,
    this.sewingThread = const ProductSelection(),
    this.jeansSewingThread = const ProductSelection(),
    this.polyesterEmbroidery = const ProductSelection(),
    this.rayon = const ProductSelection(),
    this.nonWoven = const ProductSelection(),
    this.spray = const ProductSelection(),
    this.metallicYarn = const ProductSelection(),
    this.rubberThread = const ProductSelection(),
    this.yarn = const ProductSelection(),
    this.fabric = const ProductSelection(),
  });

  /// Get all products as a map for easier iteration
  Map<String, ProductSelection> get products => {
    'SEWING THREAD': sewingThread,
    'JEANS SEWING THREAD': jeansSewingThread,
    'POLYESTER EMBROIDERY': polyesterEmbroidery,
    'RAYON': rayon,
    'NON-WOVEN': nonWoven,
    'SPRAY': spray,
    'METALLIC YARN': metallicYarn,
    'RUBBER THREAD': rubberThread,
    'YARN': yarn,
    'FABRIC': fabric,
  };

  /// Arabic product names
  static const Map<String, String> productNamesArabic = {
    'SEWING THREAD': 'خيط حياكة',
    'JEANS SEWING THREAD': 'خيط حياكة الجينز',
    'POLYESTER EMBROIDERY': 'بوليستر تطريز',
    'RAYON': 'حرير',
    'NON-WOVEN': 'الفلت والفازلين بانواعه',
    'SPRAY': 'سبراي',
    'METALLIC YARN': 'خيط معدنية(سيرما وقصب)',
    'RUBBER THREAD': 'خيط مطاطية(جوما)',
    'YARN': 'غزل',
    'FABRIC': 'قماش',
  };
}

/// Extension for Rating enum
extension RatingExtension on Rating {
  String get label {
    switch (this) {
      case Rating.a:
        return 'A';
      case Rating.b:
        return 'B';
      case Rating.c:
        return 'C';
    }
  }
}

/// Extension for CustomerType enum
extension CustomerTypeExtension on CustomerType {
  String get label {
    switch (this) {
      case CustomerType.trader:
        return 'TRADER';
      case CustomerType.manufacturer:
        return 'MANUFACTURER';
    }
  }

  String get labelArabic {
    switch (this) {
      case CustomerType.trader:
        return 'تاجر';
      case CustomerType.manufacturer:
        return 'مصنع';
    }
  }
}
