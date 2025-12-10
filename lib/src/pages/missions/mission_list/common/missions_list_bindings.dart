import 'package:get/get.dart';
import '../controllers/missions_list_controller.dart';

class MissionListBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MissionListController>(() => MissionListController());
  }
}