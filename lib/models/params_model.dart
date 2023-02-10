import 'package:parking_image/models/latlon.dart';
import 'package:parking_image/models/projection_model.dart';

class Params {
  final double zoom;
  final LatLon coords;
  final Projection projection;

  Params({required this.zoom, required this.coords, required this.projection});
}
