class Shop {
  final String id;
  final String name;
  // final String location;
  final String businessId;

  Shop({
    required this.id,
    required this.name,
    // required this.location,
    required this.businessId,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      name: json['name'] as String,
      // location: json['location'] as String,
      businessId: json['businessId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // 'location': location,
      'businessId': businessId,
    };
  }
}
