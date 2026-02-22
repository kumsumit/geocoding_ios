import 'package:flutter/material.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';

import '../template/globals.dart';

/// Demonstrates the usage of the federated [Geocoding] API.
///
/// This widget supports:
/// - Forward geocoding (address → coordinates)
/// - Reverse geocoding (coordinates → address)
/// - Locale switching
/// - Loading indicators
/// - Animated result presentation
///
/// Results are displayed in animated material cards for a polished UX.
class GeocodeWidget extends StatefulWidget {
  /// Creates a new [GeocodeWidget].
  const GeocodeWidget({super.key});

  @override
  State<GeocodeWidget> createState() => _GeocodeWidgetState();
}

class _GeocodeWidgetState extends State<GeocodeWidget> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  late final Geocoding _geocoding;

  /// Indicates whether a lookup operation is in progress.
  bool _isLoading = false;

  /// Stores formatted result strings for UI rendering.
  List<String> _results = [];

  /// Currently selected locale for geocoding.
  Locale? _locale;

  @override
  void initState() {
    super.initState();

    _geocoding = Geocoding(const GeocodingCreationParams());

    _addressController.text = 'Gronausestraat 710, Enschede';
    _latitudeController.text = '52.2165157';
    _longitudeController.text = '6.9437819';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  /// Performs reverse geocoding using the provided latitude and longitude.
  ///
  /// Displays loading state while awaiting results and shows
  /// formatted [Placemark] results in animated cards.
  Future<void> _lookupAddress() async {
    _setLoading(true);

    try {
      final latitude = double.parse(_latitudeController.text);
      final longitude = double.parse(_longitudeController.text);

      final placemarks = await _geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
        locale: _locale,
      );

      setState(() {
        _results = placemarks.map(_formatPlacemark).toList(growable: false);
      });
    } catch (e) {
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Performs forward geocoding using the provided address.
  ///
  /// Converts the resulting [Location] objects into readable strings.
  Future<void> _lookupLocation() async {
    _setLoading(true);

    try {
      final locations = await _geocoding.locationFromAddress(
        _addressController.text,
        locale: _locale,
      );

      setState(() {
        _results = locations
            .map((l) => 'Latitude: ${l.latitude}\nLongitude: ${l.longitude}')
            .toList(growable: false);
      });
    } catch (e) {
      _setError(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Updates loading state.
  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
      if (value) _results = [];
    });
  }

  /// Displays error in result list.
  void _setError(Object e) {
    setState(() {
      _results = ['Error: $e'];
    });
  }

  /// Formats a [Placemark] into a human-readable single-line address.
  ///
  /// Null and empty fields are omitted automatically.
  String _formatPlacemark(Placemark p) {
    final parts = [
      p.name,
      p.thoroughfare,
      p.subThoroughfare,
      p.locality,
      p.administrativeArea,
      p.postalCode,
      p.country,
    ].where((e) => e != null && e.isNotEmpty).toList();

    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: defaultHorizontalPadding + defaultVerticalPadding,
      child: Column(
        children: [
          const SizedBox(height: 20),

          _buildLatLngInput(),

          const SizedBox(height: 8),

          ElevatedButton(
            onPressed: _lookupAddress,
            child: const Text('Reverse Geocode'),
          ),

          const SizedBox(height: 30),

          TextField(
            controller: _addressController,
            decoration: const InputDecoration(hintText: 'Address'),
          ),

          const SizedBox(height: 8),

          ElevatedButton(
            onPressed: _lookupLocation,
            child: const Text('Forward Geocode'),
          ),

          const SizedBox(height: 20),

          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  /// Builds latitude / longitude input row.
  Widget _buildLatLngInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _latitudeController,
            decoration: const InputDecoration(hintText: 'Latitude'),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: TextField(
            controller: _longitudeController,
            decoration: const InputDecoration(hintText: 'Longitude'),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  /// Builds animated results section.
  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return const Center(child: Text('No results'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: ListView.builder(
        key: ValueKey(_results),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          return _AnimatedResultCard(
            key: ValueKey(_results[index]),
            text: _results[index],
          );
        },
      ),
    );
  }
}

/// A material card that animates on appearance.
///
/// Used for displaying individual geocoding results.
class _AnimatedResultCard extends StatelessWidget {
  final String text;

  const _AnimatedResultCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 350),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
      ),
    );
  }
}
