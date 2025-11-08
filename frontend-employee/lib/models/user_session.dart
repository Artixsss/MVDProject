class UserSession {
  final int id;
  final String username;
  final String role;
  final int roleId; // ID роли для проверок
  final String fullName;

  int get employeeId => id;
  
  // Проверки ролей
  bool get isOperator => roleId == 1;
  bool get isAdmin => roleId == 3;

  const UserSession({
    required this.id,
    required this.username,
    required this.role,
    required this.roleId,
    required this.fullName,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    try {
      final employeeData = json['employee'] ?? json['Employee'];
      String fullName = '';
      
      if (employeeData != null) {
        fullName = (employeeData['fullName'] ?? employeeData['FullName'])?.toString() ?? '';
      }
      
      if (fullName.isEmpty) {
        fullName = json['fullName']?.toString() ?? 'Сотрудник';
      }

      return UserSession(
        id: (json['id'] ?? json['Id']) as int? ?? 0,
        username: (json['username'] ?? json['Username'])?.toString() ?? '',
        role: (json['role'] ?? json['Role'])?.toString() ?? 'Operator',
        roleId: (json['roleId'] ?? json['RoleId']) as int? ?? 1, // По умолчанию оператор
        fullName: fullName,
      );
    } catch (e) {
      throw FormatException('Ошибка парсинга UserSession: $e');
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'role': role,
    'roleId': roleId,
    'fullName': fullName,
  };
}
