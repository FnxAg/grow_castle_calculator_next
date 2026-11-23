import 'package:go_router/go_router.dart';
import 'package:grow_castle_calculator_next/view/navigation/app_routes.dart';
import 'package:grow_castle_calculator_next/view/page/function/function_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_bonus_gold_calc/bonus_gold_calc_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_build_calc/build_calc_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_game_track/game_track_chart_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_game_track/game_track_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_calc/income_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_income_trend/income_trend_page.dart';
import 'package:grow_castle_calculator_next/view/page/function_wave_status/wave_status_page.dart';
import 'package:grow_castle_calculator_next/view/page/guild/guild_page.dart';
import 'package:grow_castle_calculator_next/view/page/home/home_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/player_detail_page.dart';
import 'package:grow_castle_calculator_next/view/page/public/select_user_page.dart';
import 'package:grow_castle_calculator_next/view/page/setting/setting_page.dart';
import 'package:grow_castle_calculator_next/view/page/setting_about/about_page.dart';
import 'package:grow_castle_calculator_next/view/page/setting_backup/backup_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool/tools_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool_best_line_calc/best_line_calc_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool_dragon_simulator/dragon_simulator_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool_dragon_simulator/item_rule_edit_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool_item_comparer/item_comparer_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool_quick_calculation/quick_calculation_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool_rank/models.dart';
import 'package:grow_castle_calculator_next/view/page/tool_rank/ranking_chart_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool_rank/ranking_page.dart';
import 'package:grow_castle_calculator_next/view/page/tool_search/search_page.dart';
import 'package:grow_castle_calculator_next/view/shell/main_pages.dart';
import 'package:grow_castle_calculator_next/view/shell/shell_branch_container.dart';
import 'package:grow_castle_calculator_next/view/shell/shell_scaffold.dart';
import 'package:material_ui/material_ui.dart';

final GlobalKey<NavigatorState> appRootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = createAppRouter();

GoRouter createAppRouter({String initialLocation = AppRoutes.home}) {
  // 侧栏/底栏/快捷键都按 mainPages 索引操作分支，顺序与数量必须一致
  assert(mainPages.length == 5);
  return GoRouter(
    navigatorKey: appRootNavigatorKey,
    initialLocation: initialLocation,
    routes: <RouteBase>[
      StatefulShellRoute(
        builder: (context, state, navigationShell) => ShellScaffold(
          navigationShell: navigationShell,
          location: state.uri,
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            ShellBranchContainer(children: children),
        branches: <StatefulShellBranch>[
          // 首页
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'home'),
            initialLocation: AppRoutes.home,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
                routes: <RouteBase>[_playerRoute()],
              ),
            ],
          ),
          // 功能
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'function'),
            initialLocation: AppRoutes.function,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.function,
                builder: (context, state) => const FunctionPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'build-calc',
                    builder: (context, state) => const BuildCalcPage(),
                  ),
                  GoRoute(
                    path: 'wave-status',
                    builder: (context, state) => const WaveStatusPage(),
                  ),
                  GoRoute(
                    path: 'bonus-gold',
                    builder: (context, state) => const BonusGoldCalcPage(),
                  ),
                  GoRoute(
                    path: 'income',
                    builder: (context, state) => const IncomePage(),
                  ),
                  GoRoute(
                    path: 'income-trend',
                    builder: (context, state) => const IncomeTrendPage(),
                  ),
                  GoRoute(
                    path: 'game-track',
                    builder: (context, state) => const GameTrackPage(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'chart',
                        builder: (context, state) => const GameTrackChartPage(),
                      ),
                    ],
                  ),
                  _playerRoute(),
                ],
              ),
            ],
          ),
          // 公会
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'guild'),
            initialLocation: AppRoutes.guild,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.guild,
                builder: (context, state) => const GuildPage(),
                routes: <RouteBase>[_playerRoute()],
              ),
            ],
          ),
          // 工具
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'tools'),
            initialLocation: AppRoutes.tools,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.tools,
                builder: (context, state) => const ToolsPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'rank/:kind',
                    redirect: (context, state) =>
                        _rankingKindOf(state) == null ? AppRoutes.tools : null,
                    builder: (context, state) =>
                        RankingPage(kind: _rankingKindOf(state)!),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'chart',
                        builder: (context, state) => RankingChartPage(
                          kind: _rankingKindOf(state)!,
                          date: AppRoutes.parseDate(
                            state.uri.queryParameters['date'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => const SearchPage(),
                  ),
                  _playerRoute(),
                  GoRoute(
                    path: 'guild/:name',
                    builder: (context, state) => GuildDetailPage(
                      guildName: state.pathParameters['name']!,
                      initialDate: AppRoutes.parseDate(
                        state.uri.queryParameters['date'],
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'quick-calc',
                    builder: (context, state) => const QuickCalculationPage(),
                  ),
                  GoRoute(
                    path: 'dragon-simulator',
                    builder: (context, state) => const DragonSimulatorPage(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'rules',
                        builder: (context, state) => const ItemRuleEditPage(),
                        routes: <RouteBase>[
                          buildNewItemRuleRoute(),
                          buildEditItemRuleRoute(),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'item-comparer',
                    builder: (context, state) => const ItemComparerPage(),
                    routes: <RouteBase>[buildItemComparerEquipRoute()],
                  ),
                  GoRoute(
                    path: 'best-line',
                    builder: (context, state) => const BestLineCalcPage(),
                  ),
                ],
              ),
            ],
          ),
          // 设置
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'settings'),
            initialLocation: AppRoutes.settings,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingPage(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'users',
                    builder: (context, state) => const SelectUserPage(),
                  ),
                  GoRoute(
                    path: 'backup',
                    builder: (context, state) => const BackupPage(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const AboutPage(),
                  ),
                  _playerRoute(),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('GCC Next')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            state.uri.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ),
    ),
  );
}

RankingKind? _rankingKindOf(GoRouterState state) =>
    RankingKind.values.asNameMap()[state.pathParameters['kind']];

/// 通用详情：每个分支各注册一份，按当前位置归属
GoRoute _playerRoute() => GoRoute(
  path: 'player/:name',
  builder: (context, state) =>
      PlayerDetailPage(playerName: state.pathParameters['name']!),
);
