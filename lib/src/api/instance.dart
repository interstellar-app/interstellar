import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/database/database.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/utils/utils.dart';

class APIInstance {
  APIInstance(this.client);

  final ServerClient client;

  Future<List<Instance>> federated() async {
    switch (client.software) {
      case ServerSoftware.mbin:
        const path = '/federated';
        final response = await client.get(path);

        final domains = (response.bodyJson['instances']! as List<dynamic>)
            .map((instance) => Instance.fromJson(instance))
            .toList();
        return domains;

      case ServerSoftware.lemmy:
        const path = '/federated_instances';

        final response = await client.get(path);

        final domains =
            ((response.bodyJson['federated_instances']! as JsonMap)['linked']!
                    as List<dynamic>)
                .map((instance) => Instance.fromJson(instance))
                .toList();
        return domains;

      case ServerSoftware.piefed:
        const path = '/federated_instances';

        final response = await client.get(path);

        final domains =
            ((response.bodyJson['federated_instances']! as JsonMap)['linked']!
                    as List<dynamic>)
                .map((instance) => Instance.fromJson(instance))
                .toList();
        return domains;
    }
  }
}
