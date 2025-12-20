import 'package:adaptive_screen_flutter/adaptive_screen_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:go_router/go_router.dart';
import 'package:oxedium_website/metadata/vaults.dart';
import 'package:oxedium_website/presentation/screens/staking_mob_screen.dart';
import 'package:oxedium_website/presentation/screens/staking_web_screen.dart';
import 'package:oxedium_website/presentation/screens/swap_web_screen.dart';
import 'package:oxedium_website/theme/theme.dart';
import 'package:oxedium_website/widgets/no_thumb_scroll_behavior.dart';

final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          final String? address = state.uri.queryParameters['vault'];

          if (address != null && vaultsData.values.any((vlt) => vlt.mint == address) == false) {
            return NoTransitionPage(
              child: Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Center(
                  child: Text('404',
                      style: TextStyle(
                          fontSize: 42.0, color: Theme.of(context).hintColor)),
                ),
              ),
            );
          }

          return NoTransitionPage(
          child: AdaptiveScreen(
            mobile: StakingMobScreen(vaultMint: address ?? 'So11111111111111111111111111111111111111112'),
            web: StakingWebScreen(vaultMint: address ?? 'So11111111111111111111111111111111111111112'),
          ),
        );
        },
      ),
      GoRoute(
        path: '/swap',
        pageBuilder: (context, state) {
          return const NoTransitionPage(
          child: AdaptiveScreen(
            mobile: SwapWebScreen(),
            web: SwapWebScreen(),
          ),
        );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Text('404',
                style: TextStyle(
                    fontSize: 42.0, color: Theme.of(context).hintColor)),
          ),
        ));

void main() async {
  usePathUrlStrategy();
  
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ProviderScope(
    child: MaterialApp.router(
          title: 'Oxedium',
          scrollBehavior: NoThumbScrollBehavior().copyWith(scrollbars: false),
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          routerConfig: _router,
        ),
      ),
  );
}
