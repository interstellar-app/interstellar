import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/magazine.dart';
import 'package:interstellar/src/screens/explore/magazine_screen.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class MagazinePicker extends StatefulWidget {
  final DetailedMagazineModel? value;
  final void Function(DetailedMagazineModel?) onChange;
  final bool microblogMode;

  const MagazinePicker({
    required this.value,
    required this.onChange,
    this.microblogMode = false,
    super.key,
  });

  @override
  State<MagazinePicker> createState() => _MagazinePickerState();
}

class _MagazinePickerState extends State<MagazinePicker> {
  @override
  Widget build(BuildContext context) {
    return Autocomplete<DetailedMagazineModel>(
      initialValue: widget.value == null
          ? null
          : TextEditingValue(text: widget.value!.name),
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) =>
              TextField(
                controller: textEditingController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: Text(l(context).magazine),
                  hintText: l(context).selectMagazine,
                  prefixIcon: widget.value?.icon == null
                      ? null
                      : Avatar(widget.value!.icon!, radius: 14),
                  suffixIcon: widget.value == null
                      ? null
                      : IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MagazineScreen(
                                widget.value!.id,
                                initData: widget.value!,
                                onUpdate: (newValue) =>
                                    widget.onChange(newValue),
                              ),
                            ),
                          ),
                          icon: Icon(Symbols.open_in_new_rounded),
                        ),
                  helperText: widget.microblogMode
                      ? l(context).microblog_magazineHelperText
                      : null,
                ),
                focusNode: focusNode,
                onSubmitted: (_) => onFieldSubmitted(),
                onChanged: (_) => widget.onChange(null),
              ),
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final exactFuture =
            (context.read<AppController>().api.magazines.getByName(
                      textEditingValue.text,
                    )
                    as Future<DetailedMagazineModel?>)
                .onError((error, stackTrace) => null);

        final searchFuture = context.read<AppController>().api.magazines.list(
          search: textEditingValue.text,
        );

        final [
          exactResult as DetailedMagazineModel?,
          searchResults as DetailedMagazineListModel,
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
