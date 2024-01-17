import 'package:flutter/material.dart';
import 'package:interstellar/src/api/entries.dart' as api_entries;
import 'package:interstellar/src/api/magazines.dart' as api_magazines;
import 'package:interstellar/src/api/posts.dart' as api_posts;
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:provider/provider.dart';

enum CreateType { entry, post }

class CreateScreen extends StatefulWidget {
  const CreateScreen(
    this.type, {
    this.magazineId,
    this.magazineName,
    super.key,
  });

  final CreateType type;
  final int? magazineId;
  final String? magazineName;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _titleTextController = TextEditingController();
  final TextEditingController _bodyTextController = TextEditingController();
  final TextEditingController _urlTextController = TextEditingController();
  final TextEditingController _tagsTextController = TextEditingController();
  final TextEditingController _magazineTextController = TextEditingController();
  bool _isOc = false;
  bool _isAdult = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create ${switch (widget.type) {
          CreateType.entry => 'thread',
          CreateType.post => 'post',
        }}"),
        actions: [
          IconButton(
              onPressed: () async {
                var magazineName = _magazineTextController.text;
                var client = context.read<SettingsController>().httpClient;
                var instanceHost =
                    context.read<SettingsController>().instanceHost;

                int? magazineId = widget.magazineId;
                if (magazineId == null) {
                  final magazine = await api_magazines.fetchMagazineByName(
                    client,
                    instanceHost,
                    magazineName,
                  );
                  magazineId = magazine.magazineId;
                }

                var tags = _tagsTextController.text.split(' ');

                switch (widget.type) {
                  case CreateType.entry:
                    if (_urlTextController.text.isEmpty) {
                      await api_entries.createEntry(
                        client,
                        instanceHost,
                        magazineId,
                        title: _titleTextController.text,
                        isOc: _isOc,
                        body: _bodyTextController.text,
                        lang: 'en',
                        isAdult: _isAdult,
                        tags: tags,
                      );
                    } else {
                      await api_entries.createLink(
                        client,
                        instanceHost,
                        magazineId,
                        title: _titleTextController.text,
                        url: _urlTextController.text,
                        isOc: _isOc,
                        body: _bodyTextController.text,
                        lang: 'en',
                        isAdult: _isAdult,
                        tags: tags,
                      );
                    }
                  case CreateType.post:
                    await api_posts.createPost(
                      client,
                      instanceHost,
                      magazineId,
                      body: _bodyTextController.text,
                      lang: 'en',
                      isAdult: _isAdult,
                    );
                }

                // Check BuildContext
                if (!mounted) return;

                Navigator.pop(context);
              },
              icon: const Icon(Icons.send))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (widget.type != CreateType.post)
              Padding(
                padding: const EdgeInsets.all(5),
                child: TextEditor(
                  _titleTextController,
                  label: "Title",
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextEditor(
                _bodyTextController,
                isMarkdown: true,
                label: "Body",
              ),
            ),
            if (widget.type != CreateType.post)
              Padding(
                padding: const EdgeInsets.all(5),
                child: TextEditor(
                  _urlTextController,
                  keyboardType: TextInputType.url,
                  label: "URL",
                ),
              ),
            if (widget.type != CreateType.post)
              Padding(
                padding: const EdgeInsets.all(5),
                child: TextEditor(
                  _tagsTextController,
                  label: "Tags",
                  hint: 'Separate with spaces',
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextEditor(
                _magazineTextController..text = widget.magazineName ?? '',
                label: 'Magazine',
              ),
            ),
            if (widget.type != CreateType.post)
              Row(
                children: [
                  Checkbox(
                    value: _isOc,
                    onChanged: (bool? value) => setState(() {
                      _isOc = value!;
                    }),
                  ),
                  const Text("OC"),
                ],
              ),
            Row(
              children: [
                Checkbox(
                  value: _isAdult,
                  onChanged: (bool? value) => setState(() {
                    _isAdult = value!;
                  }),
                ),
                const Text("NSFW")
              ],
            ),
          ],
        ),
      ),
    );
  }
}
