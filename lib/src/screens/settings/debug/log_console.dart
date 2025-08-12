import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';

class LogConsole extends StatefulWidget {
  const LogConsole({super.key});

  @override
  State<LogConsole> createState() => _LogConsoleState();
}

class _LogConsoleState extends State<LogConsole> {
  File? _logFile;
  List<String> _logLines = [];
  final ScrollController _controller = ScrollController();

  void _fetchLogFile() async {
    final logFile = await context.read<AppController>().logFile;
    List<String> lines = await logFile.readAsLines();
    setState(() {
      _logFile = logFile;
      _logLines = lines;
      _controller.jumpTo(_controller.position.maxScrollExtent);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchLogFile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l(context).settings_debug_log),
        actions: [
          IconButton(
            onPressed: () {
              _controller.jumpTo(_controller.position.maxScrollExtent);
            },
            icon: const Icon(Symbols.arrow_downward_rounded),
          ),
          IconButton(
            onPressed: () {
              _logFile?.writeAsString(
                '',
                mode: FileMode.writeOnly,
                flush: true,
              );
              setState(() {
                _logLines = [];
              });
            },
            icon: const Icon(Symbols.delete_rounded),
          ),
          IconButton(
            onPressed: () async {
              final useBytes = Platform.isAndroid || Platform.isIOS;
              String? filePath;
              try {
                filePath = await FilePicker.platform.saveFile(
                  fileName: 'interstellar_log.log',
                  bytes: _logFile?.readAsBytesSync(),
                );
                if (filePath == null) return;
              } catch (e) {
                final dir = await getDownloadsDirectory();
                if (dir == null)
                  throw Exception('Downloads directory not found');

                filePath = '${dir.path}/interstellar_log.log';
              }

              if (!useBytes) {
                _logFile?.copy(filePath);
              }
            },
            icon: const Icon(Symbols.save_as_rounded),
          ),
        ],
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        color: Colors.black,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          controller: _controller,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._logLines.asMap().entries.map((line) {
                  final level = switch (line.value.isEmpty
                      ? ''
                      : line.value.substring(1, 2)) {
                    'T' => Level.trace,
                    'D' => Level.debug,
                    'I' => Level.info,
                    'W' => Level.warning,
                    'E' => Level.error,
                    'F' => Level.fatal,
                    String() => Level.all,
                  };

                  return Row(
                    children: [
                      Text(
                        '${line.key}: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amberAccent,
                        ),
                      ),
                      SelectableText(
                        line.value,
                        style: TextStyle(
                          fontSize: 12,
                          color: switch (level) {
                            Level.all => Colors.white,
                            Level.trace => Colors.white,
                            Level.debug => Colors.orange,
                            Level.info => Colors.white,
                            Level.warning => Colors.amber,
                            Level.error => Colors.red,
                            Level.fatal => Colors.red,
                            Level.off => Colors.white,
                            _ => Colors.white,
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
