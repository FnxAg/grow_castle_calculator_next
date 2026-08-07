import 'package:flutter/material.dart';

class ItemComparerPage extends StatefulWidget {
  const ItemComparerPage({super.key});

  @override
  State<ItemComparerPage> createState() => _ItemComparerPageState();
}

class _ItemComparerPageState extends State<ItemComparerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('装备对比')
      ),
      body: Center(
        child: Text(
          '¯\\_(ツ)_/¯',
          style: TextStyle(fontSize: 48),
        ),
      ),
    );
  }
}