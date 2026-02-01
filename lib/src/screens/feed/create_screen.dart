import 'package:any_link_preview/any_link_preview.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/database.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/controller/router.gr.dart';
import 'package:interstellar/src/models/community.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/explore/community_owner_panel.dart';
import 'package:interstellar/src/utils/ap_urls.dart';
import 'package:interstellar/src/utils/language.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/image_selector.dart';
import 'package:interstellar/src/widgets/list_tile_switch.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/community_picker.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:interstellar/src/widgets/tags/post_flairs.dart';
import 'package:interstellar/src/widgets/tags/tag_widget.dart';
import 'package:interstellar/src/widgets/selection_menu.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

@RoutePage()
class CreateScreen extends StatefulWidget {
  const CreateScreen({
    this.crossPost,
    this.initCommunity,
    this.initTitle,
    this.initBody,
    super.key,
  });

  final PostModel? crossPost;
  final DetailedCommunityModel? initCommunity;
  final String? initTitle;
  final String? initBody;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  int _defaultTab = 0;
  DetailedCommunityModel? _community;
  final TextEditingController _titleTextController = TextEditingController();
  final TextEditingController _bodyTextController = TextEditingController();
  final TextEditingController _urlTextController = TextEditingController();
  final TextEditingController _tagsTextController = TextEditingController();
  bool _isOc = false;
  bool _isAdult = false;
  XFile? _imageFile;
  String? _altText = '';
  String _lang = '';
  List<Tag> _postFlairs = [];
  final List<TextEditingController> _pollOptions = [
    TextEditingController(text: 'Option 0'),
  ];
  bool _pollModeMultiple = false;
  Duration _pollDuration = Duration(days: 3);

  @override
  void initState() {
    super.initState();

    _lang = context.read<AppController>().profile.defaultCreateLanguage;

    if (widget.crossPost != null) {
      final post = widget.crossPost!;

      if (post.type == PostType.microblog) {
        _defaultTab = 3;
      }

      if (post.title != null) {
        _titleTextController.text = post.title!;
      }

      String body = 'Cross posted from ';
      body += genPostUrls(context, post).last.toString();
      if (post.body != null && post.body!.trim().isNotEmpty) {
        body += '\n\n';
        // Wrap original body with markdown quote
        body += post.body!.split('\n').map((line) => '> $line').join('\n');
      }
      _bodyTextController.text = body;

      final link = post.url ?? post.image?.src;
      if (link != null) {
        _urlTextController.text = link;
        _defaultTab = 2;
      }
    }

    if (widget.initCommunity != null) _community = widget.initCommunity;
    if (widget.initTitle != null) _titleTextController.text = widget.initTitle!;
    if (widget.initBody != null) _bodyTextController.text = widget.initBody!;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final bodyDraftController = context.watch<DraftsController>().auto(
      widget.crossPost != null
          ? 'crossPost:${ac.instanceHost}:${widget.crossPost!.type.name}:${widget.crossPost!.id}'
          : 'create${widget.initCommunity == null ? '' : ':${ac.instanceHost}:${widget.initCommunity!.name}'}',
    );

    Widget listViewWidget(List<Widget> children) =>
        ListView(padding: const EdgeInsets.all(12), children: children);

    Widget communityPickerWidget({bool microblogMode = false}) => Padding(
      padding: const EdgeInsets.all(8),
      child: CommunityPicker(
        value: _community,
        onChange: (newCommunity) {
          setState(() {
            _community = newCommunity;
          });
        },
        microblogMode: microblogMode,
      ),
    );

    final linkIsValid =
        _urlTextController.text.isNotEmpty &&
        (Uri.tryParse(_urlTextController.text)?.isAbsolute ?? false);

    linkEditorFetchDataCB(bool override) async {
      if (!linkIsValid) return;
      if (!override &&
          (_titleTextController.text.isNotEmpty ||
              _bodyTextController.text.isNotEmpty)) {
        return;
      }

      final metadata = await AnyLinkPreview.getMetadata(
        link: _urlTextController.text,
      );

      if (metadata == null) return;

      _titleTextController.text = metadata.title ?? '';
      _bodyTextController.text = metadata.desc ?? '';
    }

    Widget linkEditorWidget() => Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _urlTextController,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          label: Text(l(context).link),
          suffixIcon: LoadingIconButton(
            onPressed: !linkIsValid ? null : () => linkEditorFetchDataCB(true),
            icon: Icon(Symbols.globe_rounded),
          ),
          errorText: _urlTextController.text.isEmpty || linkIsValid
              ? null
              : l(context).create_link_invalid,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => linkEditorFetchDataCB(false),
      ),
    );

    Widget titleEditorWidget() => Padding(
      padding: const EdgeInsets.all(8),
      child: TextEditor(_titleTextController, label: l(context).title),
    );

    Widget bodyEditorWidget() => Padding(
      padding: const EdgeInsets.all(8),
      child: MarkdownEditor(
        _bodyTextController,
        originInstance: null,
        draftController: bodyDraftController,
        draftDisableAutoLoad: widget.initBody != null,
        onChanged: (_) => setState(() {}),
        label: l(context).body,
      ),
    );

    Widget imagePickerWidget() => ImageSelector(
      _imageFile,
      (file, altText) => setState(() {
        _imageFile = file;
        _altText = altText;
      }),
    );

    Widget tagsEditorWidget() => Padding(
      padding: const EdgeInsets.all(8),
      child: TextEditor(
        _tagsTextController,
        label: l(context).tags,
        hint: l(context).tags_hint,
      ),
    );

    Widget ocToggleWidget() => CheckboxListTile(
      title: Text(l(context).originalContent_long),
      value: _isOc,
      onChanged: (newValue) => setState(() {
        _isOc = newValue!;
      }),
      controlAffinity: ListTileControlAffinity.leading,
    );

    Widget nsfwToggleWidget() => CheckboxListTile(
      title: Text(l(context).notSafeForWork_long),
      value: _isAdult,
      onChanged: (newValue) => setState(() {
        _isAdult = newValue!;
      }),
      controlAffinity: ListTileControlAffinity.leading,
    );

    Widget languagePickerWidget() => ListTile(
      title: Text(l(context).language),
      onTap: () async {
        final newLang = await languageSelectionMenu(
          context,
        ).askSelection(context, _lang);

        if (newLang != null) {
          setState(() {
            _lang = newLang;
          });
        }
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(getLanguageName(context, _lang))],
      ),
    );

    Widget pollOptionsWidget() => Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          itemBuilder: (context, index) => ListTile(
            key: Key(index.toString()),
            title: TextEditor(_pollOptions[index]),
            trailing: Wrapper(
              shouldWrap: PlatformIs.mobile,
              parentBuilder: (child) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [child, const Icon(Symbols.drag_handle_rounded)],
              ),
              child: IconButton(
                onPressed: () => setState(() {
                  _pollOptions.remove(_pollOptions[index]);
                }),
                icon: const Icon(Symbols.delete_rounded),
              ),
            ),
          ),
          itemCount: _pollOptions.length,
          onReorder: (int oldIndex, int newIndex) => setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _pollOptions.removeAt(oldIndex);
            _pollOptions.insert(newIndex, item);
          }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ElevatedButton(
            onPressed: () => setState(() {
              _pollOptions.add(
                TextEditingController(text: 'Option ${_pollOptions.length}'),
              );
            }),
            child: Text(l(context).addChoice),
          ),
        ),
        ListTileSwitch(
          value: _pollModeMultiple,
          onChanged: (newValue) => setState(() {
            _pollModeMultiple = newValue;
          }),
          title: Text(l(context).pollMode),
        ),
        ListTile(
          title: Text(l(context).pollDuration),
          onTap: () async {
            final duration = await pollDuration(
              context,
            ).askSelection(context, _pollDuration);
            if (duration == null) return;
            setState(() {
              _pollDuration = duration;
            });
          },
          trailing: Text(pollDuration(context).getOption(_pollDuration).title),
        ),
      ],
    );

    Widget submitButtonWidget(Future<void> Function()? onPressed) => Padding(
      padding: const EdgeInsets.all(8),
      child: LoadingFilledButton(
        onPressed: onPressed,
        icon: const Icon(Symbols.send_rounded),
        label: Text(l(context).submit),
        uesHaptics: true,
      ),
    );

    Widget? postFlairsWidget() {
      if (ac.serverSoftware == ServerSoftware.piefed &&
          (_community?.flairs.isNotEmpty ?? false)) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            runSpacing: 4,
            children: [
              ..._postFlairs.map((flair) => TagWidget(tag: flair)),
              OutlinedButton.icon(
                label: Text(l(context).editFlairs),
                icon: Icon(Symbols.edit_rounded),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) => PostFlairsModal(
                    flairs: _postFlairs,
                    availableFlairs: _community!.flairs,
                    onUpdate: (flairs) => setState(() => _postFlairs = flairs),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return null;
    }

    return DefaultTabController(
      initialIndex: _defaultTab,
      length: switch (ac.serverSoftware) {
        ServerSoftware.mbin => 5,
        // Microblog tab only for Mbin
        ServerSoftware.lemmy => 4,
        ServerSoftware.piefed => 5,
        // Poll tab only for Piefed
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l(context).action_createNew),
          bottom: TabBar(
            tabs: [
              Tab(
                text: l(context).create_text,
                icon: Icon(Symbols.article_rounded),
              ),
              Tab(
                text: l(context).create_image,
                icon: Icon(Symbols.image_rounded),
              ),
              Tab(
                text: l(context).create_link,
                icon: Icon(Symbols.link_rounded),
              ),
              if (ac.serverSoftware == ServerSoftware.mbin)
                Tab(
                  text: l(context).create_microblog,
                  icon: Icon(Symbols.edit_note_rounded),
                ),
              if (ac.serverSoftware == ServerSoftware.piefed)
                Tab(text: l(context).poll, icon: Icon(Symbols.poll_rounded)),
              Tab(
                text: l(context).create_community,
                icon: Icon(Symbols.group_rounded),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            listViewWidget([
              communityPickerWidget(),
              titleEditorWidget(),
              ?postFlairsWidget(),
              bodyEditorWidget(),
              if (ac.serverSoftware == ServerSoftware.mbin) tagsEditorWidget(),
              if (ac.serverSoftware == ServerSoftware.mbin) ocToggleWidget(),
              nsfwToggleWidget(),
              languagePickerWidget(),
              submitButtonWidget(
                _community == null
                    ? null
                    : () async {
                        final tags = _tagsTextController.text.split(' ');

                        final post = await ac.api.threads.createArticle(
                          _community!.id,
                          title: _titleTextController.text,
                          isOc: _isOc,
                          body: _bodyTextController.text,
                          lang: _lang,
                          isAdult: _isAdult,
                          tags: tags,
                        );

                        if (ac.serverSoftware == ServerSoftware.piefed) {
                          await ac.api.threads.assignFlairs(
                            post.id,
                            _postFlairs.map((flair) => flair.id).toList(),
                          );
                        }
                        await bodyDraftController.discard();

                        // Check BuildContext
                        if (!context.mounted) return;

                        context.router.pop();
                      },
              ),
            ]),
            listViewWidget([
              communityPickerWidget(),
              titleEditorWidget(),
              ?postFlairsWidget(),
              imagePickerWidget(),
              if (ac.serverSoftware == ServerSoftware.mbin) tagsEditorWidget(),
              if (ac.serverSoftware == ServerSoftware.mbin) ocToggleWidget(),
              nsfwToggleWidget(),
              languagePickerWidget(),
              submitButtonWidget(
                _community == null
                    ? null
                    : () async {
                        final tags = _tagsTextController.text.split(' ');

                        final post = await ac.api.threads.createImage(
                          _community!.id,
                          title: _titleTextController.text,
                          image: _imageFile!,
                          alt: _altText ?? '',
                          isOc: _isOc,
                          body: _bodyTextController.text,
                          lang: _lang,
                          isAdult: _isAdult,
                          tags: tags,
                        );

                        if (ac.serverSoftware == ServerSoftware.piefed) {
                          await ac.api.threads.assignFlairs(
                            post.id,
                            _postFlairs.map((flair) => flair.id).toList(),
                          );
                        }

                        // Check BuildContext
                        if (!context.mounted) return;

                        context.router.pop();
                      },
              ),
            ]),
            listViewWidget([
              communityPickerWidget(),
              linkEditorWidget(),
              titleEditorWidget(),
              ?postFlairsWidget(),
              bodyEditorWidget(),
              if (ac.serverSoftware == ServerSoftware.mbin) tagsEditorWidget(),
              if (ac.serverSoftware == ServerSoftware.mbin) ocToggleWidget(),
              nsfwToggleWidget(),
              languagePickerWidget(),
              submitButtonWidget(
                _community == null || !linkIsValid
                    ? null
                    : () async {
                        final tags = _tagsTextController.text.split(' ');

                        final post = await ac.api.threads.createLink(
                          _community!.id,
                          title: _titleTextController.text,
                          url: _urlTextController.text,
                          isOc: _isOc,
                          body: _bodyTextController.text,
                          lang: _lang,
                          isAdult: _isAdult,
                          tags: tags,
                        );

                        if (ac.serverSoftware == ServerSoftware.piefed) {
                          await ac.api.threads.assignFlairs(
                            post.id,
                            _postFlairs.map((flair) => flair.id).toList(),
                          );
                        }

                        await bodyDraftController.discard();

                        // Check BuildContext
                        if (!context.mounted) return;

                        context.router.pop();
                      },
              ),
            ]),
            if (ac.serverSoftware == ServerSoftware.mbin)
              listViewWidget([
                communityPickerWidget(microblogMode: true),
                bodyEditorWidget(),
                imagePickerWidget(),
                nsfwToggleWidget(),
                languagePickerWidget(),
                submitButtonWidget(() async {
                  final community =
                      _community ??
                      await context
                          .read<AppController>()
                          .api
                          .community
                          .getByName('random');

                  if (_imageFile == null) {
                    await ac.api.microblogs.create(
                      community.id,
                      body: _bodyTextController.text,
                      lang: _lang,
                      isAdult: _isAdult,
                    );
                  } else {
                    await ac.api.microblogs.createImage(
                      community.id,
                      image: _imageFile!,
                      alt: '',
                      body: _bodyTextController.text,
                      lang: _lang,
                      isAdult: _isAdult,
                    );
                  }

                  await bodyDraftController.discard();

                  // Check BuildContext
                  if (!context.mounted) return;

                  context.router.pop();
                }),
              ]),
            if (ac.serverSoftware == ServerSoftware.piefed)
              listViewWidget([
                communityPickerWidget(),
                titleEditorWidget(),
                ?postFlairsWidget(),
                bodyEditorWidget(),
                pollOptionsWidget(),
                nsfwToggleWidget(),
                languagePickerWidget(),
                submitButtonWidget(
                  _community == null
                      ? null
                      : () async {
                          final endDate = _pollDuration == Duration()
                              ? null
                              : DateTime.now().add(_pollDuration);

                          final post = await ac.api.threads.createPoll(
                            _community!.id,
                            title: _titleTextController.text,
                            isOc: _isOc,
                            body: _bodyTextController.text,
                            lang: _lang,
                            isAdult: _isAdult,
                            choices: _pollOptions
                                .map((choice) => choice.text)
                                .toList(),
                            endDate: endDate,
                            mode: _pollModeMultiple ? 'multiple' : 'single',
                          );
                          await ac.api.threads.assignFlairs(
                            post.id,
                            _postFlairs.map((flair) => flair.id).toList(),
                          );

                          if (!context.mounted) return;
                          context.router.pop();
                        },
                ),
              ]),
            CommunityOwnerPanelGeneral(
              data: null,
              onUpdate: (newCommunity) {
                context.router.pop();
                context.router.push(
                  CommunityRoute(
                    communityId: newCommunity.id,
                    initData: newCommunity,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

SelectionMenu<Duration?> pollDuration(BuildContext context) =>
    SelectionMenu(l(context).pollDuration, [
      SelectionMenuItem(
        value: Duration(minutes: 30),
        title: l(context).pollDuration_minutes(30),
      ),
      SelectionMenuItem(
        value: Duration(hours: 1),
        title: l(context).pollDuration_hours(1),
      ),
      SelectionMenuItem(
        value: Duration(hours: 6),
        title: l(context).pollDuration_hours(6),
      ),
      SelectionMenuItem(
        value: Duration(hours: 12),
        title: l(context).pollDuration_hours(12),
      ),
      SelectionMenuItem(
        value: Duration(days: 1),
        title: l(context).pollDuration_days(1),
      ),
      SelectionMenuItem(
        value: Duration(days: 3),
        title: l(context).pollDuration_days(3),
      ),
      SelectionMenuItem(
        value: Duration(days: 7),
        title: l(context).pollDuration_days(7),
      ),
      SelectionMenuItem(
        value: Duration(days: 365),
        title: l(context).pollDuration_days(365),
      ),
    ]);
