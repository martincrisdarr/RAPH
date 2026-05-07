import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/constants.dart';

class GeocodingService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';

  static Future<LatLng?> getCoordinatesFromAddress(String address, {String? localidad}) async {
    if (address.trim().isEmpty) return null;
    
    final String loc = (localidad != null && localidad.isNotEmpty) ? localidad : 'Neuquén';
    final query = Uri.encodeComponent('$address, $loc, Argentina');
    final url = '$_baseUrl?address=$query&key=${AppConstants.googleMapsApiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print('Error en Geocoding (Address -> LatLng): $e');
    }
    return null;
  }

  static Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    final url = '$_baseUrl?latlng=$lat,$lng&key=${AppConstants.googleMapsApiKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final String fullAddress = data['results'][0]['formatted_address'];
          // "Rivadavia 42, Q8302 Neuquén, Argentina" -> ["Rivadavia 42", " Q8302 Neuquén", " Argentina"]
          final parts = fullAddress.split(',');
          if (parts.isNotEmpty) {
            return parts[0].trim(); // Devuelve solo "Rivadavia 42"
          }
          return fullAddress;
        }
      }
    } catch (e) {
      print('Error en Reverse Geocoding (LatLng -> Address): $e');
    }
    return null;
  }
}
