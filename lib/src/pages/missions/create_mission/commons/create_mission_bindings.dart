import 'package:get/get.dart';

import '../controller/create_mission_controller.dart';


class CreateMissionBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
          () => CreateMissionController(),
      fenix: true,
    );
  }
}

