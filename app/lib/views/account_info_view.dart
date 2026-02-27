import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_controller.dart';

class AccountInfoView extends StatefulWidget {
  final int userId;
  final String token;

  const AccountInfoView({super.key, required this.userId, required this.token});

  @override
  State<AccountInfoView> createState() => _AccountInfoViewState();
}

class _AccountInfoViewState extends State<AccountInfoView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userController = Provider.of<UserController>(context, listen: false);
      userController.fetchUser(widget.userId, widget.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userController = Provider.of<UserController>(context);
    final user = userController.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Account Information'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: user != null
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
                        Text(user.name),
                        SizedBox(height: 10),
                        Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(user.email),
                        SizedBox(height: 10),
                        Text('Phone', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(user.phone),
                        SizedBox(height: 10),
                        Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(user.address),
                        SizedBox(height: 10),
                        Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(user.username),
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