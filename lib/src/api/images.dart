import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

enum ImageStore { platform, catbox, imgLink }

class APIImages {
  APIImages(this.client);

  final ServerClient client;

  Future<String> uploadImage({
    required XFile image,
    ImageStore store = ImageStore.platform,
  }) async {
    // Use software default image store with catbox as a fallback for mbin.
    if (store == ImageStore.platform &&
        client.software == ServerSoftware.mbin) {
      store = ImageStore.catbox;
    }

    try {
      switch (store) {
        case ImageStore.platform:
          switch (client.software) {
            case ServerSoftware.mbin:
              throw UnimplementedError(
                'Direct image upload not available for Mbin',
              );
            case ServerSoftware.lemmy:
              const path = '/pictrs/image';

              final request = http.MultipartRequest(
                'POST',
                Uri.https(client.domain, path),
              );
              final file = http.MultipartFile.fromBytes(
                'images[]',
                await image.readAsBytes(),
                filename: basename(image.path),
                contentType: MediaType.parse(lookupMimeType(image.path)!),
              );
              request.files.add(file);

              final response = await client.sendRequest(request);

              final imageName =
                  ((response.bodyJson['files']! as List<dynamic>).first
                          as JsonMap)['file']
                      as String?;

              return 'https://${client.domain}/pictrs/image/$imageName';

            case ServerSoftware.piefed:
              const path = '/upload/image';

              final request = http.MultipartRequest(
                'POST',
                Uri.https(client.domain, client.software.apiPathPrefix + path),
              );
              final file = http.MultipartFile.fromBytes(
                'file',
                await image.readAsBytes(),
                filename: basename(image.path),
                contentType: MediaType.parse(lookupMimeType(image.path)!),
              );
              request.files.add(file);

              final response = await client.sendRequest(request);

              return response.bodyJson['url']! as String;
          }
        case ImageStore.catbox:
          const path = 'https://catbox.moe/user/api.php';

          final request = http.MultipartRequest('POST', Uri.parse(path));
          final file = http.MultipartFile.fromBytes(
            'fileToUpload',
            await image.readAsBytes(),
            filename: basename(image.path),
            contentType: MediaType.parse(lookupMimeType(image.path)!),
          );

          request.fields['reqtype'] = 'fileupload';
          request.files.add(file);

          final response = await client.sendRequest(request);
          return response.body;
        case ImageStore.imgLink:
          const path = 'https://imglink.io/upload';

          final request = http.MultipartRequest('POST', Uri.parse(path));
          final file = http.MultipartFile.fromBytes(
            'file',
            await image.readAsBytes(),
            filename: basename(image.path),
            contentType: MediaType.parse(lookupMimeType(image.path)!),
          );

          request.files.add(file);

          final response = await client.sendRequest(request);

          return ((response.bodyJson['images']! as List<dynamic>).first
                  as JsonMap)['direct_link']!
              as String;
      } //TODO: add more image store options
    } catch (e) {
      return '';
    }
  }
}
