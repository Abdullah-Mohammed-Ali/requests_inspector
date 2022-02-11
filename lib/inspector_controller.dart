import 'package:flutter/material.dart';
import 'package:requests_inspector/show_inspector_on_enum.dart';
import 'package:shake/shake.dart';

import 'request_details.dart';

///Singleton
class InspectorController extends ChangeNotifier {
  factory InspectorController({
    bool enabled = false,
    ShowInspectorOn showInspectorOn = ShowInspectorOn.Shaking,
  }) =>
      _singleton ??= InspectorController._internal(
        enabled,
        showInspectorOn,
      );

  InspectorController._internal(
    bool enabled,
    ShowInspectorOn showInspectorOn,
  )   : _enabled = enabled,
        _showInspectorOn = showInspectorOn {
    if (_enabled && _allowShaking)
      _shakeDetector = ShakeDetector.autoStart(onPhoneShake: showInspector);
  }

  static InspectorController? _singleton;

  late final bool _enabled;
  late final ShowInspectorOn _showInspectorOn;
  late final ShakeDetector _shakeDetector;

  final pageController = PageController(
    initialPage: 0,
    // if the viewportFraction is 1.0, the child pages will rebuild automatically
    // but if it less than 1.0, the pages will stay alive
    viewportFraction: 0.9999999,
  );

  int _selectedTab = 0;

  final _requestsList = <RequestDetails>[];
  RequestDetails? _selectedRequested;

  int get selectedTab => _selectedTab;
  List<RequestDetails> get requestsList => _requestsList;
  RequestDetails? get selectedRequested => _selectedRequested;
  bool get _allowShaking => [
        ShowInspectorOn.Shaking,
        ShowInspectorOn.Both,
      ].contains(_showInspectorOn);

  set selectedTab(int value) {
    if (_selectedTab == value) return;
    _selectedTab = value;
    notifyListeners();
  }

  set selectedRequested(RequestDetails? value) {
    if (_selectedRequested == value) return;
    _selectedRequested = value;
    _selectedTab = 1;
    notifyListeners();
  }

  void showInspector() => pageController.jumpToPage(1);

  void hideInspector() => pageController.jumpToPage(0);

  void addNewRequest(RequestDetails request) {
    if (!_enabled) return;
    _requestsList.insert(0, request);
    notifyListeners();
  }

  @override
  void dispose() {
    if (_allowShaking) _shakeDetector.stopListening();
    super.dispose();
  }
}
