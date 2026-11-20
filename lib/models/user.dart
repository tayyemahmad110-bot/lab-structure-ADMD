class User {
  final String name; // required, never null
  final int? age; // optional
  final String? email; // optional

  User({required this.name, this.age, this.email});

  String getDisplayAge() => age == null ? 'Age not specified' : age.toString();
}