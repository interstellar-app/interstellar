import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/poll.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:provider/provider.dart';

class Poll extends StatefulWidget {
  const Poll({required this.poll, super.key});

  final PollModel poll;

  @override
  State<Poll> createState() => _PollState();
}

class _PollState extends State<Poll> {
  bool _showResults = false;
  bool _submitted = false;
  List<PollChoiceModel> _choices = [];
  int? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _choices = widget.poll.choices.toList();
    final answer = _choices.firstWhereOrNull((choice) => choice.chosen);
    _selectedAnswer = answer?.id;

    final expired = widget.poll.endPoll.isBefore(DateTime.now());
    _submitted = (whenLoggedIn(context, answer != null) ?? true) || expired;
  }

  String getTimeTillExpire() {
    final diff = widget.poll.endPoll.difference(DateTime.now());

    final days = diff.inDays;
    final hours = diff.inHours;
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds;

    if (days.abs() != 0) {
      return l(context).pollExpiry_days(days);
    }
    if (hours.abs() != 0) {
      return l(context).pollExpiry_hours(hours);
    }
    if (minutes.abs() != 0) {
      return l(context).pollExpiry_minutes(minutes);
    }
    return l(context).pollExpiry_seconds(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    final totalVotes = _choices
        .map((choice) => choice.numVotes)
        .fold(0, (a, b) => a + b);

    return Wrapper(
      shouldWrap: !widget.poll.multiple,
      parentBuilder: (child) => RadioGroup(
        groupValue: _selectedAnswer,
        onChanged: (newValue) async {
          if (newValue == null || _submitted) return;

          setState(() {
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
                            onChanged: _submitted
                                ? null
                                : (newValue) async {
                                    if (newValue == null) return;

                                    final index = _choices.indexWhere(
                                      (c) => c.id == choice.id,
                                    );

                                    setState(() {
                                      _choices[index] = choice.copyWith(
                                        chosen: newValue,
                                      );
                                    });
                                  },
                          ),
                        if (!widget.poll.multiple)
                          Radio<int>(value: choice.id, enabled: !_submitted),
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
              Row(
                children: [
                  Text(l(context).pollVotes(totalVotes)),
                  const SizedBox(width: 10),
                  Text(getTimeTillExpire()),
                ],
              ),
              if (!_submitted)
                ElevatedButton(
                  onPressed: () async {
                    final votes = widget.poll.multiple
                        ? _choices
                              .map((choice) => choice.chosen ? choice.id : null)
                              .nonNulls
                              .toList()
                        : [_selectedAnswer!];

                    if (votes.isEmpty) {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l(context).pollSubmitError),
                          actions: [
                            OutlinedButton(
                              onPressed: () => context.router.pop(),
                              child: Text(l(context).cancel),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    final post = await ac.api.threads.votePoll(
                      widget.poll.postId,
                      votes,
                    );

                    setState(() {
                      _choices = post.poll?.choices.toList() ?? _choices;
                      _submitted = true;
                    });
                  },
                  child: Text(l(context).submit),
                ),
              if (_submitted)
                ElevatedButton(
                  onPressed: () => setState(() {
                    _showResults = !_showResults;
                  }),
                  child: Text(
                    _showResults
                        ? l(context).pollHideResults
                        : l(context).pollShowResults,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
