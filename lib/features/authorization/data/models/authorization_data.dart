class AuthorizationData {
  final String authorizedPersonName;
  final String nationalId;
  final String organization;
  final DateTime startDate;
  final DateTime endDate;

  AuthorizationData({
    required this.authorizedPersonName,
    required this.nationalId,
    required this.organization,
    required this.startDate,
    required this.endDate,
  });
}
