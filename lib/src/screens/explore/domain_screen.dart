import 'package:flutter/material.dart';
import 'package:interstellar/src/api/feed_source.dart';
import 'package:interstellar/src/models/domain.dart';
import 'package:interstellar/src/screens/feed/feed_screen.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class DomainScreen extends StatefulWidget {
  final int domainId;
  final DomainModel? initData;
  final void Function(DomainModel)? onUpdate;

  const DomainScreen(this.domainId, {super.key, this.initData, this.onUpdate});

  @override
  State<DomainScreen> createState() => _DomainScreenState();
}

class _DomainScreenState extends State<DomainScreen> {
  DomainModel? _data;

  @override
  void initState() {
    super.initState();

    _data = widget.initData;

    if (_data == null) {
      context
          .read<SettingsController>()
          .api
          .domains
          .get(widget.domainId)
          .then((value) => setState(() {
                _data = value;
              }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeedScreen(
      source: FeedSource.domain,
      sourceId: widget.domainId,
      title: _data?.name ?? '',
      details: _data != null
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _data!.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          softWrap: true,
                        ),
                      ),
                      LoadingChip(
                        selected: _data!.isUserSubscribed ?? false,
                        icon: const Icon(Symbols.people_rounded),
                        label: Text(intFormat(_data!.subscriptionsCount)),
                        onSelected: whenLoggedIn(
                          context,
                          whenLoggedIn(context, (selected) async {
                            var newValue = await context
                                .read<SettingsController>()
                                .api
                                .domains
                                .putSubscribe(_data!.id, selected);

                            setState(() {
                              _data = newValue;
                            });
                            if (widget.onUpdate != null) {
                              widget.onUpdate!(newValue);
                            }
                          }),
                        ),
                      ),
                      if (whenLoggedIn(context, true) == true)
                        LoadingIconButton(
                          onPressed: () async {
                            final newValue = await context
                                .read<SettingsController>()
                                .api
                                .domains
                                .putBlock(
                                  _data!.id,
                                  !_data!.isBlockedByUser!,
                                );

                            setState(() {
                              _data = newValue;
                            });
                            if (widget.onUpdate != null) {
                              widget.onUpdate!(newValue);
                            }
                          },
                          icon: const Icon(Symbols.block_rounded),
                          style: ButtonStyle(
                            foregroundColor: WidgetStatePropertyAll(
                                _data!.isBlockedByUser == true
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).disabledColor),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
