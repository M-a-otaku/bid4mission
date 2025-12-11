import 'route_paths.dart';
import 'package:get/get.dart';
import '../../pages/missions/create_mission/commons/create_mission_bindings.dart';
import '../../pages/missions/create_mission/views/create_mission_view.dart';
import '../../pages/missions/edit_mission/commons/edit_mission_bindings.dart';
import '../../pages/missions/mission_details/bindings/mission_detail_binding.dart';
import '../../pages/missions/mission_details/views/mission_detail_screen.dart';
import '../../pages/profile/bindings/hunter_profile_bindings.dart';
import '../../pages/profile/view/hunter_profile_view.dart';
import '../../pages/missions/edit_mission/views/edit_mission_view.dart';
import '../../pages/splash/commons/splash_bindings.dart';
import '../../pages/splash/views/splash_screen.dart';
import '../../pages/login/commons/login_bindings.dart';
import '../../pages/login/views/login_view.dart';
import '../../pages/register/common/register_bindings.dart';
import '../../pages/register/views/register_view.dart';
import '../../pages/missions/mission_list/common/missions_list_bindings.dart';
import '../../pages/missions/mission_list/views/missions_list_view.dart';


class RoutePages {
  static List<GetPage> pages = [
    GetPage(
        name: RoutePaths.splash,
        page: () => const SplashScreen(),
        binding: SplashBindings()),
    GetPage(
        name: RoutePaths.login,
        page: () => const LoginView(),
        binding: LoginBindings(),
        children: [
          GetPage(
            name: RoutePaths.register,
            page: () => const RegisterView(),
            binding: RegisterBindings(),
          )
        ]),
    GetPage(
      name: RoutePaths.missions,
      page: () => const MissionListView(),
      binding: MissionListBindings(),
      children: [
        GetPage(
          name: RoutePaths.editMissions,
          page: () => const EditMissionView(),
          binding: EditMissionBindings(),
        ),
        GetPage(
            name: RoutePaths.addMissions,
            page: () => const CreateMissionView(),
            binding: CreateMissionBindings()),
        GetPage(
            name: RoutePaths.missionDetails,
            page: () => const MissionDetailScreen(),
            binding: MissionDetailBinding()),
      ],
    ),
    GetPage(
        name: RoutePaths.profile,
        page: () => const HunterProfileScreen(),
        binding: HunterProfileBindings()),
  ];
}


