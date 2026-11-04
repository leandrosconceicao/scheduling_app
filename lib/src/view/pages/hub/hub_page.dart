import 'package:flutter/material.dart';
import '../../../application/application.dart';

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {

  late final CompanyConfigService? controller;

  @override
  void initState() {
    // controller = Get.find<CompanyConfigService>();
    super.initState();
  }

  void loadCompanies() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(      
      body: Column(
        children: [
          ListTile(
            title: Text("Estabelecimentos")
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [],
            ),
          ),
        ],
      ),
    );
  }
}