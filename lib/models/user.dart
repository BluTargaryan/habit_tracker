class User {
  final String id;
  String name;
  String username;
  String passwordHash;
  int age;
  String country;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.passwordHash,
    required this.age,
    required this.country,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'passwordHash': passwordHash,
      'age': age,
      'country': country,
    };
  }

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      username: map['username'] as String,
      passwordHash: map['passwordHash'] as String,
      age: map['age'] as int,
      country: map['country'] as String,
    );
  }
}
