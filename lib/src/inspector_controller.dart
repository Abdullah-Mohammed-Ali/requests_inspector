import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shake/shake.dart';
import 'package:share_plus/share_plus.dart';

import '../requests_inspector.dart';
import 'curl_command_generator.dart';
import 'json_pretty_converter.dart';

typedef StoppingRequestCallback = Future<RequestDetails?> Function(
    RequestDetails requestDetails);

///Singleton
class InspectorController extends ChangeNotifier {
  factory InspectorController({
    bool enabled = false,
    ShowInspectorOn showInspectorOn = ShowInspectorOn.Shaking,
    StoppingRequestCallback? onStoppingRequest,
  }) =>
      _singleton ??= InspectorController._internal(
        enabled,
        showInspectorOn,
        onStoppingRequest,
      );

  InspectorController._internal(
    bool enabled,
    ShowInspectorOn showInspectorOn,
    StoppingRequestCallback? onStoppingRequest,
  )   : _enabled = enabled,
        _showInspectorOn = showInspectorOn,
        _onStoppingRequest = onStoppingRequest {
    if (_enabled && _allowShaking)
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: showInspector,
        minimumShakeCount: 3,
      );
  }

  static InspectorController? _singleton;

  late final bool _enabled;
  late final ShowInspectorOn _showInspectorOn;
  late final ShakeDetector _shakeDetector;
  StoppingRequestCallback? _onStoppingRequest;

  final _dio = Dio(BaseOptions(validateStatus: (_) => true));
  final pageController = PageController(
    initialPage: 0,
    // if the viewportFraction is 1.0, the child pages will rebuild automatically
    // but if it less than 1.0, the pages will stay alive
    viewportFraction: 0.9999999,
  );

  int _selectedTab = 0;
  bool _userRequestStopperEnabled = false;
  bool _userResponseStopperEnabled = false;

  final _requestsList = <RequestDetails>[];
  RequestDetails? _selectedRequest;

  int get selectedTab => _selectedTab;
  bool get userRequestStopperEnabled => _userRequestStopperEnabled;
  bool get userResponseStopperEnabled => _userResponseStopperEnabled;
  List<RequestDetails> get requestsList => _requestsList;
  RequestDetails? get selectedRequest => _selectedRequest;
  bool get _allowShaking => [
        ShowInspectorOn.Shaking,
        ShowInspectorOn.Both,
      ].contains(_showInspectorOn);

  set selectedTab(int value) {
    if (_selectedTab == value) return;
    _selectedTab = value;
    notifyListeners();
  }

  set userRequestStopperEnabled(bool value) {
    if (_userRequestStopperEnabled == value) return;
    _userRequestStopperEnabled = value;
    notifyListeners();
  }

  set userResponseStopperEnabled(bool value) {
    if (_userResponseStopperEnabled == value) return;
    _userResponseStopperEnabled = value;
    notifyListeners();
  }

  set selectedRequest(RequestDetails? value) {
    if (_selectedRequest == value && _selectedTab == 1) return;
    _selectedRequest = value;
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

  void clearAllRequests() {
    if (_requestsList.isEmpty && _selectedRequest == null) return;
    _requestsList.clear();
    _selectedRequest = null;
    notifyListeners();
  }

  Future<void> runAgain() async {
    if (_selectedRequest == null) return;

    var currentRequest = _selectedRequest!;
    final sentTime = DateTime.now();
    final response = await _dio.request(
      currentRequest.url,
      queryParameters: currentRequest.queryParameters,
      data: currentRequest.requestBody,
      options: Options(
        method: currentRequest.requestMethod.name,
        headers: currentRequest.headers,
      ),
    );
    if (currentRequest != _selectedRequest) return;

    _selectedRequest = currentRequest.copyWith(
      responseBody: response.data,
      statusCode: response.statusCode,
      sentTime: sentTime,
      receivedTime: DateTime.now(),
    );

    notifyListeners();
  }

  void shareSelectedRequest([Rect? sharePositionOrigin, bool isCurl = false]) {
    String? requestShareContent;
    if (isCurl) {
      final curlCommandGenerator = CurlCommandGenerator(_selectedRequest!);
      requestShareContent = curlCommandGenerator.generate();
    } else {
      final requestMap = _selectedRequest!.toMap();
      requestShareContent = _formatMap(requestMap);
    }
    Share.share(
      requestShareContent,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  @override
  void dispose() {
    if (_allowShaking) _shakeDetector.stopListening();
    super.dispose();
  }

  String _formatMap(Map<String, dynamic> requestMap) {
    final converter = JsonPrettyConverter();
    final listOfContent = [
      for (final entry in requestMap.entries) ...[
        '=[ ${entry.key} ]===================\n',
        converter.convert(entry.value),
        '\n\n',
      ],
    ];

    return listOfContent.join();
  }

  Future<RequestDetails?> editRequest(RequestDetails requestDetails) {
    if (!_enabled || _onStoppingRequest == null) return Future.value(null);
    return _onStoppingRequest!(requestDetails);
  }
}
