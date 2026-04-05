import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/services/location_service.dart', 'r') as f:
    content = f.read()

import_sp = "import 'package:succes/services/socket_service.dart';\nimport 'package:shared_preferences/shared_preferences.dart';"
content = content.replace("import 'package:succes/services/socket_service.dart';", import_sp)

vars_old = """  bool isScouting = false;
  String? currentLine;"""
vars_new = """  bool isScouting = false;
  String? currentLine;
  bool isScoutModeEnabled = false; // Le master switch du Mode Eclaireur

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isScoutModeEnabled = prefs.getBool('scout_mode') ?? false;
  }

  Future<void> toggleScoutMode(bool value) async {
    isScoutModeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('scout_mode', value);
    if (!value) {
      stopScouting();
    }
  }"""
content = content.replace(vars_old, vars_new)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/services/location_service.dart', 'w') as f:
    f.write(content)
