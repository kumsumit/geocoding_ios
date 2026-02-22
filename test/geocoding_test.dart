import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding_ios/geocoding_ios_factory.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';

const MethodChannel _channel = MethodChannel('flutter.baseflow.com/geocoding');

final Location mockLocation = Location(
  latitude: 52.2165157,
  longitude: 6.9437819,
  timestamp: DateTime.fromMillisecondsSinceEpoch(0).toUtc(),
);

const Placemark mockPlacemark = Placemark(
  administrativeArea: 'Overijssel',
  country: 'Netherlands',
  isoCountryCode: 'NL',
  locality: 'Enschede',
  name: 'Gronausestraat',
  postalCode: '',
  street: 'Gronausestraat 710',
  subAdministrativeArea: 'Enschede',
  subLocality: 'Enschmarke',
  subThoroughfare: '',
  thoroughfare: 'Gronausestraat',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> log;

  setUp(() {
    log = <MethodCall>[];

    // Register factory
    GeocodingIOSFactory.registerWith();

    _setMockHandler((methodCall) async {
      log.add(methodCall);
      return null;
    });
  });

  group('Factory registration', () {
    test('registers GeocodingIOSFactory', () {
      expect(GeocodingPlatformFactory.instance, isA<GeocodingIOSFactory>());
    });
  });

  group('GeocodingIOS', () {
    test('locationFromAddress', () async {
      _setMockHandler((methodCall) async {
        log.add(methodCall);
        return [mockLocation.toMap()];
      });

      final geocoding = _createGeocoding();

      final locations = await geocoding.locationFromAddress('');

      _expectSingleCall(log, 'locationFromAddress', {'address': ''});

      expect(locations.single, mockLocation);
    });

    test('placemarkFromCoordinates', () async {
      _setMockHandler((methodCall) async {
        log.add(methodCall);
        return [mockPlacemark.toMap()];
      });

      final geocoding = _createGeocoding();

      final placemarks = await geocoding.placemarkFromCoordinates(0, 0);

      _expectSingleCall(log, 'placemarkFromCoordinates', {
        'latitude': 0.0,
        'longitude': 0.0,
      });

      expect(placemarks.single, mockPlacemark);
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Geocoding _createGeocoding() {
  return Geocoding(const GeocodingCreationParams());
}

void _setMockHandler(Future<dynamic> Function(MethodCall call) handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

void _expectSingleCall(
  List<MethodCall> log,
  String method,
  Map<String, dynamic> arguments,
) {
  expect(log, <Matcher>[isMethodCall(method, arguments: arguments)]);
}
