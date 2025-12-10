import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'contract_linking.dart';

class HelloUI extends StatelessWidget {
  final TextEditingController yourNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var contractLink = Provider.of<ContractLinking>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Hello World Dapp")),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: contractLink.isLoading
              ? CircularProgressIndicator()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        "Hello ${contractLink.deployedName}",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: TextField(
                          controller: yourNameController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Your Name",
                            hintText: "Enter your name...",
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: ElevatedButton(
                          onPressed: () {
                            contractLink.setName(yourNameController.text);
                            yourNameController.clear();
                          },
                          child: Text("Set Name", style: TextStyle(fontSize: 20)),
                        ),
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}