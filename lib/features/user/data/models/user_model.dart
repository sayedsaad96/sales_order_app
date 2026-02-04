import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String fullName;

  @HiveField(1)
  final String mobileNumber;

  @HiveField(2)
  final String? email;

  @HiveField(3)
  final String? jobTitle;

  UserModel({
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.jobTitle,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'mobileNumber': mobileNumber,
    'email': email,
    'jobTitle': jobTitle,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    fullName: json['fullName'],
    mobileNumber: json['mobileNumber'],
    email: json['email'],
    jobTitle: json['jobTitle'],
  );
}
