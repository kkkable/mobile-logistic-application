import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/d_driver_controller.dart';
import '../main.dart';
import 'd_account_info_view.dart';

class PersonalView extends StatefulWidget {
  final int driverId;
  final String token;

  const PersonalView({super.key, required this.driverId, required this.token});

  @override
  State<PersonalView> createState() => _PersonalViewState();
}

class _PersonalViewState extends State<PersonalView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverController = Provider.of<DriverController>(context, listen: false);
      driverController.fetchDriver(widget.driverId, widget.token);
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('driver_id');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DriverLoginForm()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverController = Provider.of<DriverController>(context);
    final driver = driverController.driver;

    return Scaffold(
      appBar: AppBar(
        title: Text('Personal'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.blue[50],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[200],
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver?.name ?? 'Loading...',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      Text(
                        driver?.username ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: Icon(Icons.account_circle, color: Colors.blue[700]),
                    title: Text('Account Information'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountInfoView(driverId: widget.driverId, token: widget.token),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red[700]),
                    title: Text('Log Out'),
                    tileColor: Colors.red[50],
                    onTap: _logout,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
