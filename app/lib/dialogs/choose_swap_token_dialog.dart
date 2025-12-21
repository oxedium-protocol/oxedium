import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/utils/extensions.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';
import 'package:oxedium_website/widgets/hover_builder.dart';
import 'package:oxedium_website/widgets/mini_button.dart';

Future<Vault?> chooseSwapTokenDialog(BuildContext context, WidgetRef ref, List<Vault> vaults) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              height: 450.0,
              width: 384.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text("Choose token"),
                        MiniButton(text: "Esc", onTap: () => Navigator.of(context).pop())
                      ],
                    ),
                  ),
                  Expanded(
                      child: ListView.builder(
                      itemCount: vaults.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: HoverBuilder(
                            builder: (context, hover) => CustomInkWell(
                              onTap: () => Navigator.of(context).pop(vaults[index]),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: 70.0,
                                width: MediaQuery.of(context).size.width,
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  border: Border.all(color: hover ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.05))
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Image.network(vaults[index].logoUrl, height: 21.0, width: 21.0),
                                            const SizedBox(width: 8.0),
                                            Text(vaults[index].symbol),
                                            const SizedBox(width: 8.0),
                                            const Icon(Icons.verified_outlined, color: Colors.greenAccent, size: 15.0)
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(vaults[index].mint.cutText(), style: const TextStyle(color: Colors.grey, fontSize: 12.0))
                                          ],
                                        ),
                                      ],
                                    ),
                                    // const Column(
                                    //   mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    //   crossAxisAlignment: CrossAxisAlignment.end,
                                    //   children: [
                                    //     Text('1.4'),
                                    //     Text('\$125.64', style: TextStyle(color: Colors.grey, fontSize: 12.0))
                                    //   ],
                                    // )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                    }),
                  )
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
