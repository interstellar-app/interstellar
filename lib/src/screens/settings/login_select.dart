import 'package:auto_route/annotations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/api/api.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/screens/settings/login_confirm.dart';
import 'package:interstellar/src/utils/router.gr.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/server_software_indicator.dart';
import 'package:interstellar/src/widgets/text_editor.dart';
import 'package:provider/provider.dart';

final Map<String, List<(String, ServerSoftware)>> _recommendedInstances = {
  '': [
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
  ],
  'bg': [('feddit.bg', ServerSoftware.lemmy)],
  'da': [('feddit.dk', ServerSoftware.lemmy)],
  'de': [
    ('gehirneimer.de', ServerSoftware.mbin),
    ('feddit.org', ServerSoftware.lemmy),
    ('discuss.tchncs.de', ServerSoftware.lemmy),
  ],
  'es': [
    ('feddit.cl', ServerSoftware.lemmy),
    ('chachara.club', ServerSoftware.lemmy),
  ],
  'fi': [
    ('sopuli.xyz', ServerSoftware.lemmy),
    ('suppo.fi', ServerSoftware.lemmy),
  ],
  'fr': [
    ('jlai.lu', ServerSoftware.lemmy),
    ('lemmy.ca', ServerSoftware.lemmy),
    ('feddit.fr', ServerSoftware.piefed),
  ],
  'it': [
    ('feddit.it', ServerSoftware.lemmy),
    ('diggita.com', ServerSoftware.lemmy),
    ('lemminielettrici.it', ServerSoftware.lemmy),
  ],
  'ja': [
    ('lm.korako.me', ServerSoftware.lemmy),
    ('pf.korako.me', ServerSoftware.piefed),
  ],
  'ko': [('lemmy.funami.tech', ServerSoftware.lemmy)],
  'lt': [('group.lt', ServerSoftware.lemmy)],
  'ms': [('monyet.cc', ServerSoftware.lemmy)],
  'nl': [
    ('feddit.nl', ServerSoftware.lemmy),
    ('lemy.nl', ServerSoftware.lemmy),
  ],
  'pl': [
    ('szmer.info', ServerSoftware.lemmy),
    ('fedit.pl', ServerSoftware.lemmy),
  ],
  'pt': [
    ('lemmy.eco.br', ServerSoftware.lemmy),
    ('forum.ayom.media', ServerSoftware.lemmy),
    ('bolha.forum', ServerSoftware.lemmy),
    ('lemmy.pt', ServerSoftware.lemmy),
  ],
  'sv': [
    ('feddit.nu', ServerSoftware.lemmy),
    ('aggregatet.org', ServerSoftware.lemmy),
  ],
};

@RoutePage()
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

    final shouldPop = await context.router.push(
      LoginConfirmRoute(software: software, server: host),
    );

    if (shouldPop == true) {
      // Check BuildContext
      if (!mounted) return;

      context.router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;

    genServerList(List<(String, ServerSoftware)> servers) => servers
        .map(
          (v) => ListTile(
            title: Row(
              children: [ServerSoftwareIndicator(label: v.$1, software: v.$2)],
            ),
            onTap: () => _initiateLogin(v.$1),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l(context).addAccount)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextEditor(
            _instanceHostController,
            label: l(context).instanceHost,
            keyboardType: TextInputType.url,
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
          if (_recommendedInstances.containsKey(language)) ...[
            ...genServerList(_recommendedInstances[language]!),
            Divider(),
          ],
          ...genServerList(_recommendedInstances['']!),
        ],
      ),
    );
  }
}
