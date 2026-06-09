class AppRoutes {
  const AppRoutes._();

  static const aiFormCheck = '/ai/form-check';
  static const aiBodyAnalysis = '/ai/body-analysis';

  static String aiFormCheckLocation({required String exerciseId}) {
    return Uri(
      path: aiFormCheck,
      queryParameters: {'exerciseId': exerciseId},
    ).toString();
  }
}
