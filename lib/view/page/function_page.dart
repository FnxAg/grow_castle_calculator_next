import 'package:flutter/material.dart';
import 'package:grow_castle_calculator_next/view/page/function/bonus_gold_calc.dart';
import 'package:grow_castle_calculator_next/view/page/function/income_page.dart';
import 'package:grow_castle_calculator_next/view/page/function/wave_status_page.dart';
import 'package:grow_castle_calculator_next/view/widget/user_page_scaffold.dart';

/// 当前用户的更多信息与状态
class FunctionPage extends StatelessWidget {
  const FunctionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserPageScaffold(
      title: '功能',
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bolt),
            title: const Text('跳波状态'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WaveStatusPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.percent),
            title: const Text('收入百分比计算'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BonusGoldCalcPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on),
            title: const Text('收入'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const IncomePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
