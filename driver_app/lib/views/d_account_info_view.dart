import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/d_driver_controller.dart';

class AccountInfoView extends StatefulWidget {
  final int driverId;
  final String token;

  const AccountInfoView({super.key, required this.driverId, required this.token});

  @override
  State<AccountInfoView> createState() => _AccountInfoViewState();
}

class _AccountInfoViewState extends State<AccountInfoView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverController = Provider.of<DriverController>(context, listen: false);
      driverController.fetchDriver(widget.driverId, widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverController = Provider.of<DriverController>(context);
    final driver = driverController.driver;

    return Scaffold(
      appBar: AppBar(
        title: Text('Account Information'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: driver != null
          ? ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(driver.name),
                        SizedBox(height: 10),
                        Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(driver.email),
                        SizedBox(height: 10),
                        Text('Phone', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(driver.phone),
                        SizedBox(height: 10),
                        Text('Vehicle Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(driver.vehicleDetails),
                        SizedBox(height: 10),
                        Text('Working Time', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(driver.workingTime),
                        SizedBox(height: 10),
                        Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(driver.username),
                        SizedBox(height: 10),
                        Text('Average Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(driver.avgRating.toStringAsFixed(2)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
