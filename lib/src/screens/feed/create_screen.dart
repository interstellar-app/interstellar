import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/models/magazine.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/explore/magazine_owner_panel.dart';
import 'package:interstellar/src/screens/explore/magazine_screen.dart';
import 'package:interstellar/src/utils/language.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/image_selector.dart';
import 'package:interstellar/src/widgets/loading_button.dart';
import 'package:interstellar/src/widgets/magazine_picker.dart';
import 'package:interstellar/src/widgets/markdown/drafts_controller.dart';
import 'package:interstellar/src/widgets/markdown/markdown_editor.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({
    this.initMagazine,
    this.initTitle,
    this.initBody,
    super.key,
  });

  final DetailedMagazineModel? initMagazine;
  final String? initTitle;
  final String? initBody;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  DetailedMagazineModel? _magazine;
  final TextEditingController _titleTextController = TextEditingController();
  final TextEditingController _bodyTextController = TextEditingController();
  final TextEditingController _urlTextController = TextEditingController();
  final TextEditingController _tagsTextController = TextEditingController();
  bool _isOc = false;
  bool _isAdult = false;
  XFile? _imageFile;
  String? _altText = '';
  String _lang = '';

  @override
  void initState() {
    super.initState();

    _lang = context.read<AppController>().profile.defaultPostLanguage;

    if (widget.initMagazine != null) _magazine = widget.initMagazine;
    if (widget.initTitle != null) _titleTextController.text = widget.initTitle!;
    if (widget.initBody != null) _bodyTextController.text = widget.initBody!;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.watch<AppController>();

    final bodyDraftController = context.watch<DraftsController>().auto(
        'create:${widget.initMagazine == null ? '' : ':${ac.instanceHost}:${widget.initMagazine!.name}'}');

    Widget listViewWidget(List<Widget> children) => ListView(
          padding: const EdgeInsets.all(12),
          children: children,
        );

    Widget magazinePickerWidget({bool microblogMode = false}) => Padding(
          padding: const EdgeInsets.all(8),
          child: MagazinePicker(
            value: _magazine,
            onChange: (newMagazine) {
              setState(() {
                _magazine = newMagazine;
              });
            },
            microblogMode: microblogMode,
          ),
        );

    final linkIsValid = _urlTextController.text.isNotEmpty &&
        (Uri.tryParse(_urlTextController.text)?.isAbsolute ?? false);

    linkEditorFetchDataCB(bool override) async {
      if (!linkIsValid) return;
      if (!override &&
          (_titleTextController.text.isNotEmpty ||
              _bodyTextController.text.isNotEmpty)) return;

      final metadata =
          await AnyLinkPreview.getMetadata(link: _urlTextController.text);

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
              onPressed:
                  !linkIsValid ? null : () => linkEditorFetchDataCB(true),
              icon: Icon(Symbols.globe_rounded),
            ),
            errorText: _urlTextController.text.isEmpty || linkIsValid
                ? null
                : l(context).create_link_invalid,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => linkEditorFetchDataCB(false),
        ));

    Widget titleEditorWidget() => Padding(
          padding: const EdgeInsets.all(8),
          child: TextEditor(
            _titleTextController,
            label: l(context).title,
          ),
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
            final newLang = await languageSelectionMenu(context).askSelection(
              context,
              _lang,
            );

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

    Widget submitButtonWidget(Future<void> Function()? onPressed) => Padding(
          padding: const EdgeInsets.all(8),
          child: LoadingFilledButton(
            onPressed: onPressed,
            icon: const Icon(Symbols.send_rounded),
            label: Text(l(context).submit),
          ),
        );

    return DefaultTabController(
      length: switch (ac.serverSoftware) {
        ServerSoftware.mbin => 5,
        // No Microblog tab on Lemmy
        ServerSoftware.lemmy => 4,
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
              Tab(
                text: l(context).create_magazine,
                icon: Icon(Symbols.group_rounded),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            listViewWidget(
              [
                magazinePickerWidget(),
                titleEditorWidget(),
                bodyEditorWidget(),
                if (ac.serverSoftware == ServerSoftware.mbin)
                  tagsEditorWidget(),
                if (ac.serverSoftware == ServerSoftware.mbin) ocToggleWidget(),
                nsfwToggleWidget(),
                languagePickerWidget(),
                submitButtonWidget(_magazine == null
                    ? null
                    : () async {
                        final tags = _tagsTextController.text.split(' ');

                        await ac.api.threads.createArticle(
                          _magazine!.id,
                          title: _titleTextController.text,
                          isOc: _isOc,
                          body: _bodyTextController.text,
                          lang: _lang,
                          isAdult: _isAdult,
                          tags: tags,
                        );

                        await bodyDraftController.discard();

                        // Check BuildContext
                        if (!mounted) return;

                        Navigator.pop(context);
                      })
              ],
            ),
            listViewWidget(
              [
                magazinePickerWidget(),
                titleEditorWidget(),
                imagePickerWidget(),
                if (ac.serverSoftware == ServerSoftware.mbin)
                  tagsEditorWidget(),
                if (ac.serverSoftware == ServerSoftware.mbin) ocToggleWidget(),
                nsfwToggleWidget(),
                languagePickerWidget(),
                submitButtonWidget(_magazine == null
                    ? null
                    : () async {
                        final tags = _tagsTextController.text.split(' ');

                        await ac.api.threads.createImage(
                          _magazine!.id,
                          title: _titleTextController.text,
                          image: _imageFile!,
                          alt: _altText ?? '',
                          isOc: _isOc,
                          body: _bodyTextController.text,
                          lang: _lang,
                          isAdult: _isAdult,
                          tags: tags,
                        );

                        // Check BuildContext
                        if (!mounted) return;

                        Navigator.pop(context);
                      })
              ],
            ),
            listViewWidget(
              [
                magazinePickerWidget(),
                linkEditorWidget(),
                titleEditorWidget(),
                bodyEditorWidget(),
                if (ac.serverSoftware == ServerSoftware.mbin)
                  tagsEditorWidget(),
                if (ac.serverSoftware == ServerSoftware.mbin) ocToggleWidget(),
                nsfwToggleWidget(),
                languagePickerWidget(),
                submitButtonWidget(_magazine == null || !linkIsValid
                    ? null
                    : () async {
                        final tags = _tagsTextController.text.split(' ');

                        await ac.api.threads.createLink(
                          _magazine!.id,
                          title: _titleTextController.text,
                          url: _urlTextController.text,
                          isOc: _isOc,
                          body: _bodyTextController.text,
                          lang: _lang,
                          isAdult: _isAdult,
                          tags: tags,
                        );

                        await bodyDraftController.discard();

                        // Check BuildContext
                        if (!mounted) return;

                        Navigator.pop(context);
                      })
              ],
            ),
            if (ac.serverSoftware == ServerSoftware.mbin)
              listViewWidget(
                [
                  magazinePickerWidget(microblogMode: true),
                  bodyEditorWidget(),
                  imagePickerWidget(),
                  nsfwToggleWidget(),
                  languagePickerWidget(),
                  submitButtonWidget(() async {
                    final magazine = _magazine ??
                        await context
                            .read<AppController>()
                            .api
                            .magazines
                            .getByName('random');

                    if (_imageFile == null) {
                      await ac.api.microblogs.create(
                        magazine.id,
                        body: _bodyTextController.text,
                        lang: _lang,
                        isAdult: _isAdult,
                      );
                    } else {
                      await ac.api.microblogs.createImage(
                        magazine.id,
                        image: _imageFile!,
                        alt: '',
                        body: _bodyTextController.text,
                        lang: _lang,
                        isAdult: _isAdult,
                      );
                    }

                    await bodyDraftController.discard();

                    // Check BuildContext
                    if (!mounted) return;

                    Navigator.pop(context);
                  })
                ],
              ),
            MagazineOwnerPanelGeneral(
              data: null,
              onUpdate: (newMagazine) {
                Navigator.pop(context);

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MagazineScreen(
                      newMagazine.id,
                      initData: newMagazine,
                    ),
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
