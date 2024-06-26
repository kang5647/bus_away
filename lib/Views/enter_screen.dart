/// The main page after user's login is successful
/// This page displays the map of Singapore, with iconic landmarks plotted and 4 different bus services for user to choose
import 'dart:async';
import 'package:bus_app/Control/add_markers.dart';
import 'package:bus_app/Control/weather_control.dart';
import 'package:bus_app/Utility/app_colors.dart';
import 'package:bus_app/Views/home_screen.dart';
import 'package:bus_app/Views/select_bus_screen.dart';
import 'package:bus_app/Widgets/blue_intro_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:location/location.dart';

///Timer for setting the interval between each weather info retrieval
Timer? _timer;

class EnterScreen extends StatefulWidget {
  const EnterScreen({super.key});

  @override
  State<EnterScreen> createState() => _EnterScreenState();
}

class _EnterScreenState extends State<EnterScreen> {
  /// Goole Map controller
  final Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController googleMapController;

  ///  A Weather API Manager
  WeatherApiClient client = WeatherApiClient();

  /// A class model for storing weather data
  Weather? data;

  /// A set of markers to display on Google map, this includes: static markers(iconic landmarks) and user's current location
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};

  /// A library function to add all the static markers
  MarkerAdder staticMarkers = MarkerAdder();

  /// Defines bitmap images for different markers' icon
  BitmapDescriptor busstopIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor cityIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor natureIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor culturalIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor boardingIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor alightingIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor mylocationIcon = BitmapDescriptor.defaultMarker;

  /// Whether the markers'icon is set properly before display
  bool isSetupReady = false;

  /// The current location of the user
  Location myLocation = Location();

  /// Marker ID for the marker of user's location
  late MarkerId locationMarkerID;

  /// Setting the markers'icon using asset images
  void setCustomMarkerIcon() async {
    //used to set the icons for our markers in project (can custom markers)
    busstopIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, "assets/mapmarker_icons/Pin_source.png");

    cityIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, "assets/mapmarker_icons/Pin_city.png");

    natureIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, "assets/mapmarker_icons/Pin_nature.png");

    culturalIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, "assets/mapmarker_icons/Pin_history.png");

    mylocationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty, "assets/mapmarker_icons/Badge.png");

    /// Set the static markers'icon
    staticMarkers.setStaticMarkers(
        busstopIcon, cityIcon, natureIcon, culturalIcon);

    /// Add all the static markers to local markers set
    markers.addAll(staticMarkers.getMarkers);

    /// Setstate after markers'icon are all set
    setState(() {
      isSetupReady = true;
    });
  }

  // Function to determine the live location of the user
  /*
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error("Location services is disabled!");
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error("Location permission denied!");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location permission permanetly deined!");
    }

    print("Success!");
    Position position = await Geolocator.getCurrentPosition();

    return position;
  } */

  /// Get the weather data using [WeatherAPIClient]
  Future<void> getData() async {
    data = await client.getCurrentWeather();
    print(data!.temp);
    print(data!.cityName);
  }

  @override
  void initState() {
    setCustomMarkerIcon();
    super.initState();
    client.getCurrentWeather();

    /// Declare a new timer with 10 minutes duration
    _timer =
        Timer.periodic(const Duration(minutes: 10), (Timer t) => getData());
    rootBundle.loadString('assets/map_style.txt').then((string) {});
  }

  @override
  Widget build(BuildContext context) {
    /// Initialize firestore connection
    WidgetsFlutterBinding.ensureInitialized;

    /// Display map after user's location is retrieved and all markers are set
    return Scaffold(
        body: Stack(children: [
      Positioned(
        top: 180,
        left: 0,
        right: 0,
        bottom: 0,
        child: FutureBuilder(
            future: myLocation.getLocation(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                    '${snapshot.error} occurred',
                    style: const TextStyle(fontSize: 18),
                  ));
                } else if (snapshot.hasData) {
                  LocationData currentLocation = snapshot.data!;
                  print("$currentLocation.latitude $currentLocation.longitude");
                  locationMarkerID = MarkerId("currentLocation");
                  var marker = {
                    locationMarkerID: Marker(
                        markerId: locationMarkerID,
                        position: LatLng(currentLocation.latitude!,
                            currentLocation.longitude!),
                        icon: mylocationIcon)
                  };
                  markers.addAll(marker);
                  return isSetupReady
                      ? GoogleMap(
                          initialCameraPosition: CameraPosition(
                              target: LatLng(
                                currentLocation.latitude!,
                                currentLocation.longitude!,
                              ),
                              zoom: 15.5),
                          zoomControlsEnabled: false,
                          compassEnabled: false,
                          markers: markers.values.toSet(),
                          onMapCreated: (GoogleMapController controller) {
                            googleMapController = controller;
                            _controller.complete(controller);
                          },
                        )
                      : const Center(
                          child: Text('Loading Maps...'),
                        );
                }
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            }),
      ),

      // Background image
      blueHeader(),

      // Greeting text
      FutureBuilder(
          future: getData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return buildTextField(data!.temp, data!.mainDesc);
            }
            return Positioned(
              top: 30,
              left: 20,
              right: 20,
              child: Container(
                width: Get.width,
                height: 50,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 5,
                          blurRadius: 5)
                    ]),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: CircularProgressIndicator(),
                    )
                  ],
                ),
              ),
            );
          }),

      /// Build the Bus Route for user's selection
      buildRouteSelection(),

      /// Set the current location's marker and adjust camera position to user's current location after clicked
      Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 35.0, right: 12.0),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.blueColor,
            child: InkWell(
              onTap: () async {
                LocationData currentLocation = await myLocation.getLocation();
                setState(() {
                  googleMapController.animateCamera(
                      CameraUpdate.newCameraPosition(CameraPosition(
                          target: LatLng(currentLocation.latitude!,
                              currentLocation.longitude!),
                          zoom: 14)));
                  var marker = Marker(
                    markerId: locationMarkerID,
                    position: LatLng(
                        currentLocation.latitude!, currentLocation.longitude!),
                    icon: mylocationIcon,
                  );
                  markers[locationMarkerID] = marker;
                });
              },
              child: const Icon(
                Icons.my_location,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),

      /// Build Bottom swipe up sheet for logout
      buildBottomSheet(),
    ]));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Build bus route box for selection
Widget buildRouteSelection() {
  return Positioned(
    top: 100,
    left: 10,
    right: 10,
    child: Container(
      width: Get.width,
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    busRouteIcon(
                      route: "City",
                      picPath: "assets/city.png",
                    ),
                    SizedBox(
                      width: 45,
                    ),

                    busRouteIcon(
                      route: "Heartland",
                      picPath: "assets/house.png",
                    ),
                    //busRouteIcon("Heartland", "assets/house.png"),
                    SizedBox(
                      width: 45,
                    ),
                    busRouteIcon(
                      route: "Nature",
                      picPath: "assets/nature.png",
                    ),
                    //busRouteIcon("Nature", "assets/nature.png"),
                    SizedBox(
                      width: 45,
                    ),
                    busRouteIcon(
                      route: "Cultural",
                      picPath: "assets/history.png",
                    ),
                    //busRouteIcon("Cultural", "assets/history.png"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Build the bottom sheet for logout function
Widget buildBottomSheet() {
  return Align(
    alignment: Alignment.bottomCenter,
    child: InkWell(
      child: Container(
        width: Get.width * 0.9,
        height: 25,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 3.0,
                blurRadius: 3.0)
          ],
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12), topLeft: Radius.circular(12)),
        ),
        child: Center(
          child: Container(
            width: Get.width * 0.4,
            height: 4,
            color: Colors.black45.withOpacity(0.25),
          ),
        ),
      ),
      onTap: () async {
        Get.bottomSheet(
          bottomSheetControl(),
        );
      },
    ),
  );
}

/// Set bus route selections' icon
class busRouteIcon extends StatefulWidget {
  const busRouteIcon({
    super.key,
    required this.route,
    required this.picPath,
  });
  final String route;
  final String picPath;

  @override
  State<busRouteIcon> createState() => _busRouteIconState();
}

class _busRouteIconState extends State<busRouteIcon> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: InkWell(
        onTap: () {
          if (widget.route == "City") {
            _timer?.cancel();

            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const Select_Bus_UI(
                          query: "7",
                        )));

            print("clicked");
          } else if (widget.route == "Heartland") {
            _timer?.cancel();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const Select_Bus_UI(query: "168")));
            print("clicked");
          } else if (widget.route == "Nature") {
            _timer?.cancel();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const Select_Bus_UI(query: "52")));
            print("clicked");
          } else if (widget.route == "Cultural") {
            _timer?.cancel();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const Select_Bus_UI(query: "147")));

            print("clicked");
          }
        },
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.lightBlueColor.withOpacity(0.7),
              radius: 26,
              backgroundImage: ExactAssetImage(widget.picPath),
            ),
            const SizedBox(
              height: 5.0,
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                widget.route,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.black),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Build the greeting text at the top of the page
Widget buildTextField(double? temp, String? mainDesc) {
  return Positioned(
    top: 30,
    left: 20,
    right: 20,
    child: Container(
      width: Get.width,
      height: 50,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 5,
                blurRadius: 5)
          ]),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Row(
              children: [
                // Weather Icon
                buildWeatherIcon(temp, mainDesc),

                // Spaced Seprator
                const SizedBox(
                  width: 30,
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 5.0, left: 5.0),
                  child: Text(
                    "Hello there! Select a Bus Route",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.normal, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Show bottomsheet content when it is pressed
Widget bottomSheetControl() {
  return Container(
    width: Get.width,
    height: Get.height * 0.3,
    decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        color: Colors.white),
    child: Padding(
      padding: const EdgeInsets.only(left: 15.0, top: 10.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            const Text(
              "Settings",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "Logins",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              width: Get.width,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      spreadRadius: 4,
                      blurRadius: 10),
                ],
              ),
              child: InkWell(
                onTap: () {
                  Get.to(() => const HomeScreen());
                },
                child: Row(
                  children: const [
                    Text(
                      "Log Out",
                      style: TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ]),
    ),
  );
}

/// Set weather icon for different temperatures
Widget buildWeatherIcon(double? temp, String? mainDesc) {
  IconData myIcon;
  Color myColor;
  if (mainDesc == "Thunderstorm") {
    myIcon = Icons.thunderstorm;
    myColor = Colors.grey;
  } else if (mainDesc == "Drizzle") {
    myIcon = CupertinoIcons.cloud_drizzle_fill;
    myColor = AppColors.blueColor;
  } else if (mainDesc == "Rain") {
    myIcon = CupertinoIcons.cloud_rain_fill;
    myColor = AppColors.blueColor;
  } else if (mainDesc == "Snow") {
    myIcon = CupertinoIcons.snow;
    myColor = Colors.lightBlue;
  } else if (mainDesc == "Clouds") {
    myIcon = Icons.wb_cloudy;
    myColor = AppColors.greyColor;
  } else {
    myIcon = Icons.sunny;
    myColor = Colors.orange;
  }
  return Container(
    child: Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: [
          Icon(
            myIcon,
            size: 20,
            color: myColor,
          ),
          const SizedBox(
            height: 3.0,
          ),
          Text(
            "${temp!.toPrecision(1)}°",
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.normal),
          )
        ],
      ),
    ),
  );
}
