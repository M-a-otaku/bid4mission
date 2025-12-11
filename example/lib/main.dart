import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await GetStorage.init();
  } catch (_) {}
  runApp(const App());
}

