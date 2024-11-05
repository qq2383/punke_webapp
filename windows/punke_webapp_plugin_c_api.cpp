#include "include/punke_webapp/punke_webapp_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "punke_webapp_plugin.h"

void PunkeWebappPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  punke_webapp::PunkeWebappPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
