import 'package:get/get.dart';

import '../controller/edit_mission_controller.dart';

class EditMissionBindings extends Bindings {
  @override
  void dependencies() {
    final parameters = Get.parameters;
    Get.lazyPut(() => EditMissionController(missionId: parameters['id'] ?? ''));
  }
}


