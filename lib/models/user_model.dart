class UserModel {
  final String uid;
  final String email;
  final String name;
  final TaxProfile taxProfile;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.taxProfile,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    TaxProfile? taxProfile,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      taxProfile: taxProfile ?? this.taxProfile,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'taxProfile': taxProfile.toMap(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      taxProfile: TaxProfile.fromMap(map['taxProfile'] ?? {}),
    );
  }
}

class TaxProfile {
  final bool isIndividualDependentRelatives;
  final bool isDisabledIndividual;
  final bool isHusbandWifeAlimony;
  final bool isDisabledHusbandWife;
  final int childReliefCount;
  final int disabledChildCount;
  final bool isParentsGrandparentsMedical;

  TaxProfile({
    this.isIndividualDependentRelatives = true,
    this.isDisabledIndividual = false,
    this.isHusbandWifeAlimony = false,
    this.isDisabledHusbandWife = false,
    this.childReliefCount = 0,
    this.disabledChildCount = 0,
    this.isParentsGrandparentsMedical = false,
  });

  TaxProfile copyWith({
    bool? isIndividualDependentRelatives,
    bool? isDisabledIndividual,
    bool? isHusbandWifeAlimony,
    bool? isDisabledHusbandWife,
    int? childReliefCount,
    int? disabledChildCount,
    bool? isParentsGrandparentsMedical,
  }) {
    return TaxProfile(
      isIndividualDependentRelatives: isIndividualDependentRelatives ?? this.isIndividualDependentRelatives,
      isDisabledIndividual: isDisabledIndividual ?? this.isDisabledIndividual,
      isHusbandWifeAlimony: isHusbandWifeAlimony ?? this.isHusbandWifeAlimony,
      isDisabledHusbandWife: isDisabledHusbandWife ?? this.isDisabledHusbandWife,
      childReliefCount: childReliefCount ?? this.childReliefCount,
      disabledChildCount: disabledChildCount ?? this.disabledChildCount,
      isParentsGrandparentsMedical: isParentsGrandparentsMedical ?? this.isParentsGrandparentsMedical,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isIndividualDependentRelatives': isIndividualDependentRelatives,
      'isDisabledIndividual': isDisabledIndividual,
      'isHusbandWifeAlimony': isHusbandWifeAlimony,
      'isDisabledHusbandWife': isDisabledHusbandWife,
      'childReliefCount': childReliefCount,
      'disabledChildCount': disabledChildCount,
      'isParentsGrandparentsMedical': isParentsGrandparentsMedical,
    };
  }

  factory TaxProfile.fromMap(Map<String, dynamic> map) {
    return TaxProfile(
      isIndividualDependentRelatives: map['isIndividualDependentRelatives'] ?? true,
      isDisabledIndividual: map['isDisabledIndividual'] ?? false,
      isHusbandWifeAlimony: map['isHusbandWifeAlimony'] ?? false,
      isDisabledHusbandWife: map['isDisabledHusbandWife'] ?? false,
      childReliefCount: map['childReliefCount'] ?? 0,
      disabledChildCount: map['disabledChildCount'] ?? 0,
      isParentsGrandparentsMedical: map['isParentsGrandparentsMedical'] ?? false,
    );
  }

  // Calculate Fixed Reliefs based on Profile
  double calculateFixedRelief() {
    double total = 0;
    if (isIndividualDependentRelatives) total += 9000;
    if (isDisabledIndividual) total += 6000;
    if (isHusbandWifeAlimony) total += 4000;
    if (isDisabledHusbandWife) total += 5000;
    total += (childReliefCount * 2000);
    total += (disabledChildCount * 6000);
    return total;
  }

  List<Map<String, dynamic>> getFixedReliefItems() {
    final List<Map<String, dynamic>> items = [];
    if (isIndividualDependentRelatives) {
      items.add({'title': 'Individual & Dependent', 'amount': 9000.0, 'limit': 9000.0});
    }
    if (isDisabledIndividual) {
      items.add({'title': 'Disabled Individual', 'amount': 6000.0, 'limit': 6000.0});
    }
    if (isHusbandWifeAlimony) {
      items.add({'title': 'Husband/Wife/Alimony', 'amount': 4000.0, 'limit': 4000.0});
    }
    if (isDisabledHusbandWife) {
      items.add({'title': 'Disabled Husband/Wife', 'amount': 5000.0, 'limit': 5000.0});
    }
    if (childReliefCount > 0) {
      items.add({'title': 'Child Relief ($childReliefCount)', 'amount': childReliefCount * 2000.0, 'limit': childReliefCount * 2000.0});
    }
    if (disabledChildCount > 0) {
      items.add({'title': 'Disabled Child ($disabledChildCount)', 'amount': disabledChildCount * 6000.0, 'limit': disabledChildCount * 6000.0});
    }
    return items;
  }
}
