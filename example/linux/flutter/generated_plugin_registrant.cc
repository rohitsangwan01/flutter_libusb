//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_libusb/flutter_libusb_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flutter_libusb_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterLibusbPlugin");
  flutter_libusb_plugin_register_with_registrar(flutter_libusb_registrar);
}
