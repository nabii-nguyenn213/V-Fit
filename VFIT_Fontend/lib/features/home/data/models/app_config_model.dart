class AppConfigModel {
  const AppConfigModel({
    required this.appName,
    this.slogan,
    this.supportEmail,
    this.termsUrl,
    this.privacyUrl,
    this.latestVersion,
    this.minSupportedVersion,
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.updatedAt,
  });

  final String appName;
  final String? slogan;
  final String? supportEmail;
  final String? termsUrl;
  final String? privacyUrl;
  final String? latestVersion;
  final String? minSupportedVersion;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final DateTime? updatedAt;

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      appName: json['appName']?.toString() ?? 'V-FIT',
      slogan: json['slogan']?.toString(),
      supportEmail: json['supportEmail']?.toString(),
      termsUrl: json['termsUrl']?.toString(),
      privacyUrl: json['privacyUrl']?.toString(),
      latestVersion: json['latestVersion']?.toString(),
      minSupportedVersion: json['minSupportedVersion']?.toString(),
      maintenanceMode: json['maintenanceMode'] == true,
      maintenanceMessage: json['maintenanceMessage']?.toString(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}
