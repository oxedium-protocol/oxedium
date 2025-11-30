import 'package:flutter/material.dart';
import 'package:oxedium_website/utils/links.dart';
import 'package:oxedium_website/widgets/social_icon_button.dart';

class BasementMobWidget extends StatelessWidget {
  const BasementMobWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade900,
            width: 0.5,
          ),
        ),
      ),
      child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SocialIconButton(
                assetPath: "assets/icons/x_icon.svg",
                url: twitterLink,
                height: 14.0,
              ),
              SizedBox(width: 20.0),
              SocialIconButton(
                assetPath: "assets/icons/telegram_icon.svg",
                url: telegramLink,
                height: 14.0,
              ),
              SizedBox(width: 20.0),
              SocialIconButton(
                assetPath: "assets/icons/chat.svg",
                url: telegramChatLink,
                height: 14.0,
              ),
              SizedBox(width: 20.0),
              SocialIconButton(
                assetPath: "assets/icons/github_icon.svg",
                url: repGithubLink,
                height: 16.0,
              ),
            ],
          ),
    );
  }
}
