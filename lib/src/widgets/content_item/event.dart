import 'package:flutter/material.dart';
import 'package:interstellar/src/controller/controller.dart';
import 'package:interstellar/src/models/event.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/open_webpage.dart';
import 'package:provider/provider.dart';

class Event extends StatefulWidget {
  const Event({required this.event, super.key});

  final EventModel event;

  @override
  State<Event> createState() => _EventState();
}

class _EventState extends State<Event> {
  @override
  Widget build(BuildContext context) {
    final ac = context.read<AppController>();

    final hasLocation =
        widget.event.location != null &&
        widget.event.location!.address.isNotEmpty &&
        widget.event.location!.city.isNotEmpty &&
        widget.event.location!.country.isNotEmpty;

    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(dateOnlyFormat(widget.event.start.toLocal())),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(timeOnlyFormat(widget.event.start.toLocal())),
            ),
            if (widget.event.end != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Duration: ${dateDiffFormat(start: widget.event.start, end: widget.event.end)}',
                ),
              ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Join mode: ${switch (widget.event.joinMode) {
                  JoinMode.free => l(context).eventMode_free,
                  JoinMode.restricted => l(context).eventMode_restricted,
                  JoinMode.external => l(context).eventMode_external,
                  JoinMode.invite => l(context).eventMode_invite,
                }}',
              ),
            ),
            if (widget.event.eventFee != 0)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Fee: ${widget.event.eventFee} ${widget.event.eventFeeCurrency}',
                ),
              ),
          ],
        ),
        if (hasLocation)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (widget.event.location!.address.isNotEmpty)
                  Text('Address: ${widget.event.location!.address}'),
                if (widget.event.location!.city.isNotEmpty)
                  Text('City: ${widget.event.location!.city}'),
                if (widget.event.location!.country.isNotEmpty)
                  Text('Country: ${widget.event.location!.country}'),
              ],
            ),
          ),
        if (widget.event.onlineUrl != null)
          Card.outlined(
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 40,
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.event.onlineUrl!.host,
                        style: Theme.of(context).textTheme.bodyMedium!.apply(
                          decoration: TextDecoration.underline,
                        ),
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                    ],
                  ),
                ),
                onTap: () =>
                    openWebpagePrimary(context, widget.event.onlineUrl!),
                onLongPress: () =>
                    openWebpageSecondary(context, widget.event.onlineUrl!),
                onSecondaryTap: () =>
                    openWebpageSecondary(context, widget.event.onlineUrl!),
              ),
            ),
          ),
      ],
    );
  }
}
