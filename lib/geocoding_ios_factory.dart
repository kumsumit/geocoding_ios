import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'geocoding_ios.dart';

/// iOS factory responsible for creating [GeocodingIOS] instances.
///
/// This class registers the iOS implementation with the
/// [GeocodingPlatformFactory] and provides platform-specific
/// [Geocoding] objects.
class GeocodingIOSFactory extends GeocodingPlatformFactory {

  @override
  Geocoding createGeocoding(GeocodingCreationParams params) {
    return GeocodingIOS(params);
  }
}
