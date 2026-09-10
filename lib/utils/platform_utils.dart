import 'dart:io';

bool get isAndroid => Platform.isAndroid;
bool get isIOS => Platform.isIOS;
bool get isWindows => Platform.isWindows;
bool get isLinux => Platform.isLinux;
bool get isMacOS => Platform.isMacOS;
bool get isMobile => isAndroid || isIOS;
bool get isDesktop => isWindows || isLinux || isMacOS;