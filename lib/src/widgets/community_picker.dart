import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class CommunityPicker extends StatefulWidget {
  final DetailedCommunityModel? value;
  final void Function(DetailedCommunityModel?) onChange;
  final bool microblogMode;

  const CommunityPicker({
    required this.value,
    required this.onChange,
    this.microblogMode = false,
    super.key,
  });

  @override
  State<CommunityPicker> createState() => _CommunityPickerState();
}

class _CommunityPickerState extends State<CommunityPicker> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<DetailedCommunityModel>(
      initialValue: widget.value == null
          ? null
          : TextEditingValue(text: widget.value!.name),
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) =>
              TextField(
                controller: textEditingController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: Text(l(context).community),
                  hintText: l(context).selectCommunity,
                  prefixIcon: widget.value?.icon == null
                      ? null
                      : Avatar(widget.value!.icon!, radius: 14),
                  suffixIcon: widget.value == null
                      ? null
                      : IconButton(
                          onPressed: () => context.router.push(
                            CommunityRoute(
                              communityId: widget.value!.id,
                              initData: widget.value!,
                              onUpdate: (newValue) => widget.onChange(newValue),
                            ),
                          ),
                          icon: Icon(Symbols.open_in_new_rounded),
                        ),
                  helperText: widget.microblogMode
                      ? l(context).microblog_communityHelperText
                      : null,
                ),
                focusNode: focusNode,
                onSubmitted: (_) => onFieldSubmitted(),
                onChanged: (_) => widget.onChange(null),
              ),
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final exactFuture =
            (context.read<AppController>().api.community.getByName(
                      textEditingValue.text,
                    )
                    as Future<DetailedCommunityModel?>)
                .onError((error, stackTrace) => null);

        final searchFuture = context.read<AppController>().api.community.list(
          search: textEditingValue.text,
        );

        final [
          exactResult as DetailedCommunityModel?,
          searchResults as DetailedCommunityListModel,
        ] = await Future.wait([
          exactFuture,
          searchFuture,
        ]);

        return exactResult == null
            ? searchResults.items
            : [
                exactResult,
                ...searchResults.items.where(
                  (item) => item.id != exactResult.id,
                ),
              ];
      },
      displayStringForOption: (option) => option.name,
      onSelected: widget.onChange,
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: AlignmentDirectional.topStart,
        child: Material(
          elevation: 4.0,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 250),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                final option = options.elementAt(index);
                return InkWell(
                  onTap: () {
                    onSelected(option);
                  },
                  child: Builder(
                    builder: (BuildContext context) {
                      final bool highlight =
                          AutocompleteHighlightedOption.of(context) == index;
                      if (highlight) {
                        SchedulerBinding.instance.addPostFrameCallback((
                          Duration timeStamp,
                        ) {
                          Scrollable.ensureVisible(context, alignment: 0.5);
                        }, debugLabel: 'AutocompleteOptions.ensureVisible');
                      }
                      return Container(
                        color: highlight ? Theme.of(context).focusColor : null,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            if (option.icon != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Avatar(option.icon!, radius: 14),
                              ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  option.name,
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
