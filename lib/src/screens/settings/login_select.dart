import 'package:flutter/material.dart';
import 'package:interstellar/src/api/api.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/screens/settings/login_confirm.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/server_software_indicator.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:provider/provider.dart';

final List<(String, ServerSoftware)> _recommendedInstances = [
  ('kbin.earth', ServerSoftware.mbin),
  ('fedia.io', ServerSoftware.mbin),
  ('thebrainbin.org', ServerSoftware.mbin),
  ('kbin.melroy.org', ServerSoftware.mbin),
  ('lemmy.world', ServerSoftware.lemmy),
  ('lemmy.ml', ServerSoftware.lemmy),
  ('sh.itjust.works', ServerSoftware.lemmy),
  ('lemmy.dbzer0.com', ServerSoftware.lemmy),
  ('piefed.social', ServerSoftware.piefed),
  ('feddit.online', ServerSoftware.piefed),
];

class LoginSelectScreen extends StatefulWidget {
  const LoginSelectScreen({super.key});

  @override
  State<LoginSelectScreen> createState() => _LoginSelectScreenState();
}

class _LoginSelectScreenState extends State<LoginSelectScreen> {
  final TextEditingController _instanceHostController = TextEditingController();

  Future<void> _initiateLogin(String host) async {
    final software = await getServerSoftware(host);

    // Check BuildContext
    if (!mounted) return;

    if (software == null) {
      throw Exception(l(context).unsupportedSoftware(host));
    }

    await context.read<AppController>().saveServer(software, host);

    // Check BuildContext
    if (!mounted) return;

    final shouldPop = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LoginConfirmScreen(software, host),
      ),
    );

    if (shouldPop == true) {
      // Check BuildContext
      if (!mounted) return;

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l(context).addAccount)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextEditor(
            _instanceHostController,
            label: l(context).instanceHost,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _instanceHostController.text.isEmpty
                ? null
                : () => _initiateLogin(_instanceHostController.text),
            child: Text(l(context).continue_),
          ),
          const SizedBox(height: 32),
          Text(
            l(context).recommendedInstances,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          ..._recommendedInstances.map(
            (v) => ListTile(
              title: Row(
                children: [
                  ServerSoftwareIndicator(label: v.$1, software: v.$2),
                ],
              ),
              onTap: () => _initiateLogin(v.$1),
            ),
          ),
        ],
      ),
    );
  }
}
