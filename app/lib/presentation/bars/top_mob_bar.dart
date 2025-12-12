import 'package:flutter/material.dart';
import 'package:oxedium_website/utils/links.dart';
import 'package:oxedium_website/widgets/circle_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:js' as js;

class TopMobBar extends ConsumerStatefulWidget {
  const TopMobBar({super.key});

  @override
  ConsumerState<TopMobBar> createState() => _TopMobBarState();
}

class _TopMobBarState extends ConsumerState<TopMobBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      width: MediaQuery.of(context).size.width,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Oxedium', style: TextStyle(fontSize: 18.0, fontFamily: "Audiowide")),
            Row(
              children: [
                CircleButton(assetUrl: "assets/icons/x_icon.svg", onTap: () => js.context.callMethod('open', [twitterLink]), padding: 10.0),
                const SizedBox(width: 4.0),
                CircleButton(assetUrl: "assets/icons/doc_icon.svg", onTap: () => js.context.callMethod('open', [litepaperLink]), padding: 10.0),
                const SizedBox(width: 4.0),
                CircleButton(assetUrl: "assets/icons/github_icon.svg", onTap: () => js.context.callMethod('open', [repGithubLink]), padding: 8.0)
              ],
            )
          ],
        ),
      ),
    );
  }
}
