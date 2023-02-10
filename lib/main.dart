import 'package:flutter/material.dart';

import 'package:parking_image/models/latlon.dart';
import 'package:parking_image/models/pixels_model.dart';
import 'package:parking_image/models/projection_model.dart';
import 'package:parking_image/models/tile_number_model.dart';

import 'models/params_model.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController latitudeTextController = TextEditingController();
  final TextEditingController longitudeTextController = TextEditingController();
  final TextEditingController zoomTextController = TextEditingController();
  late PixelCoords pixelCoords;
  late TileNumber tileNumber;
  bool isRequestCompleted = false;
  static RegExp latValidate = RegExp(
      r'^(\+|-)?(?:90(?:(?:\.0{1,6})?)|(?:[0-9]|[1-8][0-9])(?:(?:\.[0-9]{1,6})?))$');
  static RegExp lonValidate = RegExp(
      r'^(\+|-)?(?:180(?:(?:\.0{1,6})?)|(?:[0-9]|[1-9][0-9]|1[0-7][0-9])(?:(?:\.[0-9]{1,6})?))$');
// Доступные проекции и соответствующие значения эксцентриситетов.
  List<Projection> projections = [
    Projection(name: "wgs84Mercator", eccentricity: 0.0818191908426),
    Projection(name: "sphericalMercator", eccentricity: 0),
  ];
  // Для вычисления номера нужного тайла следует задать параметры:
  // - уровень масштабирования карты;
  // - географические координаты объекта, попадающего в тайл;
  // - проекцию, для которой нужно получить тайл.

  late Params params;
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    latitudeTextController.text = '55.792032';
    longitudeTextController.text = '37.605608';
    zoomTextController.text = '18';
  }

  @override
  void dispose() {
    super.dispose();
    latitudeTextController.dispose();
    longitudeTextController.dispose();
    zoomTextController.dispose();
  }

// Функция для перевода географических координат объекта
// в глобальные пиксельные координаты.
  PixelCoords fromGeoToPixels(
      double lat, double lon, Projection projection, double zoom) {
    double pi = math.pi;
    double e = projection.eccentricity;
    double x, y;
    double rho;
    double beta;
    double phi;
    double theta;
    rho = math.pow(2, zoom + 8) / 2;
    beta = lat * pi / 180;
    phi = (1 - e * math.sin(beta)) / (1 + e * math.sin(beta));
    theta = math.tan(pi / 4 + beta / 2) * math.pow(phi, e / 2);

    x = rho * (1 + lon / 180);
    y = rho * (1 - math.log(theta) / pi);
    return PixelCoords(x: x, y: y);
  }

// Функция для расчета номера тайла на основе глобальных пиксельных координат.
  TileNumber fromPixelsToTileNumber(double x, double y) {
    return TileNumber(x: (x / 256).floor(), y: (y / 256).floor());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Вычисление тайла с паркингом относительно долготы, широты и зума'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 18.0, right: 18, top: 18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 18.0),
                child: Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: latitudeTextController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Широта',
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            icon: const Icon(Icons.arrow_forward),
                          ),
                          validator: (value) {
                            if (value != null && value.isEmpty) {
                              return 'Поле не должно быть пустым';
                            }
                            if (!latValidate.hasMatch(value!)) {
                              return 'Значение поля невалидно';
                            }
                            return null;
                          },
                        ),
                      ),
                      const VerticalDivider(
                        color: Colors.red,
                        thickness: 10,
                        width: 10,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: longitudeTextController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Долгота',
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            icon: const Icon(
                              Icons.arrow_upward,
                            ),
                          ),
                          validator: (value) {
                            if (value != null && value.isEmpty) {
                              return 'Поле не должно быть пустым';
                            }
                            if (!lonValidate.hasMatch(value!)) {
                              return 'Значение поля невалидно';
                            }
                            return null;
                          },
                        ),
                      ),
                      const VerticalDivider(
                        color: Colors.red,
                        thickness: 10,
                        width: 10,
                      ),
                      Expanded(
                          child: TextFormField(
                        controller: zoomTextController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Зум',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          icon: const Icon(
                            Icons.zoom_in_map,
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.isEmpty) {
                            return 'Поле не должно быть пустым';
                          }
                          if (double.parse(value!) < 2 ||
                              double.parse(value) > 21) {
                            return 'Значение зума должно быть больше 1 и меньше 22';
                          }
                          return null;
                        },
                      ))
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        isRequestCompleted = false;
                      });
                      params = Params(
                          zoom: double.tryParse(zoomTextController.text)!,
                          coords: LatLon(
                              lat:
                                  double.tryParse(latitudeTextController.text)!,
                              lon: double.tryParse(
                                  longitudeTextController.text)!),
                          projection: projections[0]);

                      // Переведем географические координаты объекта в глобальные пиксельные координаты.
                      pixelCoords = fromGeoToPixels(params.coords.lat,
                          params.coords.lon, params.projection, params.zoom);

                      // Посчитаем номер тайла на основе пиксельных координат.
                      tileNumber =
                          fromPixelsToTileNumber(pixelCoords.x, pixelCoords.y);

                      setState(() {
                        isRequestCompleted = true;
                      });
                    }
                  },
                  child: const Text('Расчитать тайл'),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              if (isRequestCompleted)
                ResultingTile(
                    x: tileNumber.x, y: tileNumber.y, zoom: params.zoom),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultingTile extends StatelessWidget {
  const ResultingTile(
      {super.key, required this.x, required this.y, required this.zoom});
  final int x;
  final int y;
  final double zoom;
  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://core-carparks-renderer-lots.maps.yandex.net/maps-rdr-carparks/tiles?l=carparks&x=$x&y=$y&z=$zoom&scale=1&lang=ru_RU',
      errorBuilder: (context, error, stackTrace) {
        return const Text('По этим координатам нет тайла с парковками');
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(seconds: 1),
          curve: Curves.fastOutSlowIn,
          child: Column(
            children: [
              Text('Номер тайла: [$x, $y]'),
              const SizedBox(
                height: 18,
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}
