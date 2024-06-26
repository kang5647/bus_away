/// Display the current bus stop along the bus route and the number of stops away from the alighting point
/// Send notifications to the user when it is only one stop away and when the bus has arrived at the alighting point
import 'dart:async';
import 'package:bus_app/Control/arrival_manager.dart';
import 'package:bus_app/Views/enter_screen.dart';
import 'package:get/get.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:bus_app/Utility/app_colors.dart';

class busArrivedScreen extends StatefulWidget {
  const busArrivedScreen(
      {super.key,
      required this.busNo,
      required this.alighting,
      required this.boarding,
      required this.arrivalManager,
      required this.onBusStopChanged});
  final String busNo;
  final String boarding;
  final String alighting;
  final ArrivalManager arrivalManager;

  ///A call back function to tell [BusMap] google camera to set to the current bus stop location
  final Function(String) onBusStopChanged;

  @override
  State<busArrivedScreen> createState() => _busArrivedScreenState();
}

class _busArrivedScreenState extends State<busArrivedScreen> {
  /// Number of stops between the current bus stop and the alighting stop
  late int _stopsAway;

  /// Current bus stop name
  late String _curStop;

  /// Whether to send notification
  static bool notify = false;

  /// Whether the end notification has been sent
  static bool endNotification = false;
  late Timer mytimer;

  ///Set the timer with 30s duration to check if the bus has reached the next bus stop, then update [_curStop] and [_stopsAway] accordingly
  void startTimer() {
    mytimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
      } else {
        setState(() {
          updateStopsAway(widget.arrivalManager);
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    //setArrivalManager();
    startTimer();

    _stopsAway = widget.arrivalManager.noOfStopsAway;
    _curStop = widget.arrivalManager.busStopList[widget.arrivalManager.curIndex]
        ['BusStopName'];
  }

  @override
  void dispose() {
    mytimer.cancel();
    super.dispose();
  }

  /// Update the text value of the [busArrivedScreen]
  void updateStopsAway(ArrivalManager arrivalManager) async {
    //await arrivalManager.updateCurStop();
    final int stopsAway = arrivalManager.getNoOfStopsAway();
    final String curStop = widget.arrivalManager
        .busStopList[widget.arrivalManager.curIndex]['BusStopName'];

    if (_curStop != curStop) {
      widget.onBusStopChanged(curStop);
      Future.delayed(const Duration(seconds: 5)).then((value) =>
          setState(() => {_stopsAway = stopsAway, _curStop = curStop}));
      //print('No of Stops Away: ${stopsAway}\n');
    }
  }

  /// Show the updated [_curStop] and [_stopsAway] and trigger notification if
  /// 1. The bus is one stop away from the alighting point
  /// 2. The bus has arrived at the alighting point
  @override
  Widget build(BuildContext context) {
    String nextStop = widget.arrivalManager
        .getBusStopCode(widget.arrivalManager.curIndex + 1);
    return FutureBuilder(
        future: widget.arrivalManager.updateArrival(nextStop),
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data == null) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasData) {
              DateTime est = snapshot.data!;
              widget.arrivalManager.updateCurStop(est);
              updateStopsAway(widget.arrivalManager);
              print(
                  'curStop = ${_curStop}, nextStop = ${nextStop}, no. of stops away = ${widget.arrivalManager.getNoOfStopsAway()}');

              /// If [_stopsAway] == 1 and user has not been notified before
              if (widget.arrivalManager.noOfStopsAway == 1 && notify == false) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  Get.snackbar(
                      "Notification", "You are arriving at your destination!",
                      icon: Icon(
                        Icons.error,
                        color: Colors.white,
                      ),
                      snackPosition: SnackPosition.TOP,
                      backgroundColor: AppColors.lightColor,
                      borderRadius: 20,
                      margin: EdgeInsets.all(15),
                      colorText: AppColors.blackColor);
                  notify = true;
                });

                /// If [_stopsAway] == 0 and end notification has not been set
              } else if (_stopsAway == 0 && !endNotification) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Notification"),
                        content: Text("You have arrived. Enjoy your trip!"),
                        actions: [
                          TextButton(
                            child: const Text("Back to Main Page"),
                            onPressed: () => {
                              //endNotification = false,
                              Navigator.pop(context),
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EnterScreen()))
                            },
                          ),
                        ],
                        elevation: 24.0,
                      );
                    },
                    barrierDismissible: false,
                  );
                  endNotification = true;
                });
              }
              return BusArrivalContainer();
            }
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        }));
  }

  /// Display [_curStop] and [_stopsAway] using text widget
  Widget BusArrivalContainer() {
    return Container(
      width: 400,
      //height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.lightBlueColor,
      ),
      margin: const EdgeInsets.fromLTRB(10, 500, 10, 0),
      padding: EdgeInsets.all(12),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                  '${widget.arrivalManager.getBusStopName(widget.arrivalManager.boardingIndex)} - ${widget.arrivalManager.getBusStopName(widget.arrivalManager.destIndex)}',
                  style: TextStyle(
                      color: AppColors.darkBlueColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  width: 350,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.darkBlueColor.withOpacity(1.0),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text("Current bus stop: ",
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            )),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text("${_curStop}",
                            style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                      )
                    ],
                  )),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  width: 350,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.darkBlueColor.withOpacity(1.0),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text("Number of stops away: ",
                            style: TextStyle(
                              color: AppColors.whiteColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text("${_stopsAway}",
                            style: TextStyle(
                              color: AppColors.blackColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                      )
                    ],
                  )),
            ),
          ]),
    );
  }
}
