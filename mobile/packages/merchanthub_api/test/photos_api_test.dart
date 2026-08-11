import 'package:test/test.dart';
import 'package:merchanthub_api/merchanthub_api.dart';


/// tests for PhotosApi
void main() {
  final instance = MerchanthubApi().getPhotosApi();

  group(PhotosApi, () {
    // Delete Photo
    //
    // Delete a photo. Merchants can delete their business photos.
    //
    //Future deletePhotoApiV1PhotosPhotoIdDelete(String photoId) async
    test('test deletePhotoApiV1PhotosPhotoIdDelete', () async {
      // TODO
    });

    // List Business Photos
    //
    // List gallery photos for a business.
    //
    //Future<BuiltList<PhotoResponse>> listBusinessPhotosApiV1PhotosBusinessBusinessIdGet(String businessId) async
    test('test listBusinessPhotosApiV1PhotosBusinessBusinessIdGet', () async {
      // TODO
    });

    // Upload Photo
    //
    // Upload a photo for a business gallery or review. Triggers AI image analysis.  **Request:** multipart form — file, business_id OR review_id, photo_type, caption **Response:** Photo with AI image insights (suggestions only)
    //
    //Future<PhotoResponse> uploadPhotoApiV1PhotosUploadPost(MultipartFile file, { String businessId, String reviewId, String photoType, String caption }) async
    test('test uploadPhotoApiV1PhotosUploadPost', () async {
      // TODO
    });

  });
}
