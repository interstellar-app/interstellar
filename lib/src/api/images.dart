import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:interstellar/src/api/client.dart';
import 'package:interstellar/src/controller/server.dart';
import 'package:interstellar/src/utils/globals.dart';
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

              final response = await client.postMultipart(
                path,
                files: {'images[]': image},
              );

              final imageName =
                  ((response.bodyJson['files']! as List<dynamic>).first
                          as JsonMap)['file']
                      as String?;

              return 'https://${client.domain}/pictrs/image/$imageName';

            case ServerSoftware.piefed:
              const path = '/upload/image';

              final response = await client.postMultipart(
                path,
                files: {'file': image},
              );

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

          final response = await http.Response.fromStream(
            await appHttpClient.send(request),
          );
          ServerClient.checkResponseSuccess(request.url, response);

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

          final response = await http.Response.fromStream(
            await appHttpClient.send(request),
          );
          ServerClient.checkResponseSuccess(request.url, response);

          return ((response.bodyJson['images']! as List<dynamic>).first
                  as JsonMap)['direct_link']!
              as String;
      } // TODO(olorin99): add more image store options
    } catch (e) {
      return '';
    }
  }
}
