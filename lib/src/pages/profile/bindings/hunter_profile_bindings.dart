import 'package:get/get.dart';

import '../controller/hunter_profile_controller.dart';

class HunterProfileBindings extends Bindings {
  @override
  void dependencies() {
    final parameters = Get.parameters;
    Get.lazyPut(
        () => HunterProfileController(hunterId: parameters['id'] ?? ''));
  }
}
