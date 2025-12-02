import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/poll.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class Poll extends StatefulWidget {
  const Poll({super.key, required this.poll});

  final PollModel poll;

  @override
  State<Poll> createState() => _PollState();
}

class _PollState extends State<Poll> {
  bool _showResults = false;

  List<PollChoiceModel> _choices = [];
  int? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _choices = widget.poll.choices.toList();
    final answer = _choices.firstWhereOrNull((choice) => choice.chosen);
    _selectedAnswer = answer?.id;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    final int totalVotes = _choices
        .map((choice) => choice.numVotes)
        .fold(0, (a, b) => a + b);

    return Wrapper(
      shouldWrap: !widget.poll.multiple,
      parentBuilder: (child) => RadioGroup(
        groupValue: _selectedAnswer,
        onChanged: (newValue) async {
          if (newValue == null || _selectedAnswer != null) return;
          final post = await ac.api.threads.votePoll(
            widget.poll.postId,
            newValue,
          );
          setState(() {
            _choices = post.poll?.choices.toList() ?? _choices;
            _selectedAnswer = newValue;
          });
        },
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._choices.map(
            (choice) => Stack(
              alignment: AlignmentGeometry.centerLeft,
              children: [
                if (_showResults)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight:
                          2 *
                          (Theme.of(context).textTheme.bodyLarge?.fontSize ??
                              20),
                    ),
                    child: FractionallySizedBox(
                      heightFactor: 1,
                      widthFactor: max(
                        choice.numVotes / max(totalVotes, 1),
                        0.00001,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (widget.poll.multiple)
                          Checkbox(
                            value: choice.chosen,
                            onChanged: (newValue) async {
                              final post = await ac.api.threads.votePoll(
                                widget.poll.postId,
                                choice.id,
                              );
                              setState(() {
                                _choices =
                                    post.poll?.choices.toList() ?? _choices;
                              });
                            },
                          ),
                        if (!widget.poll.multiple)
                          Radio<int>(
                            value: choice.id,
                            enabled: _selectedAnswer == null,
                          ),
                        Text(choice.text),
                      ],
                    ),
                    if (_showResults)
                      Text(
                        '${((choice.numVotes / max(totalVotes, 1)) * 100).toInt()}%',
                      ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$totalVotes votes'),
              ElevatedButton(
                onPressed: () => setState(() {
                  _showResults = !_showResults;
                }),
                child: Text('Show results'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
