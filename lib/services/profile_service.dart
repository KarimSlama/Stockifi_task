// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/count.dart';
import 'package:stocklio_flutter/models/organization.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../models/profile.dart';

// Services
import '../models/response.dart';
import 'auth_service.dart';

// Utils
import '../utils/logger_util.dart';

abstract class ProfileService {
  Stream<Profile> getProfileStream();
  Future<Response<Profile>> fetchProfile();
  Future<Response<String>> updateProfile(Profile profile);
  Future<void> setNotificationSetting(
    bool isNotificationsOn, {
    String? deviceToken,
  });
  Stream<Organization> getOrgStream();
  Future<Response<Organization>> fetchOrg();
  Stream<List<Profile>> getOrgProfilesStreams();
  Future<Response<Count?>> fetchLatestCount(String userId);
}

class ProfileServiceImpl implements ProfileService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;

  ProfileServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Stream<Profile> getProfileStream() {
    Stream<Profile> profileStream = Stream.value(Profile());
    final uid = _authService.uid;
    try {
      profileStream = _firestore
          .doc('users/$uid')
          .snapshots()
          .map((snapshot) => Profile.fromSnapshot(snapshot));
      logger.i('ProfileService - getProfileStream is successful');
    } catch (error, stackTrace) {
      SentryUtil.error('ProfileService.getProfileStream() error!',
          'ProfileService class', error, stackTrace);
    }
    return profileStream;
  }

  @override
  Future<Response<Profile>> fetchProfile() async {
    Profile? profile;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final snapshot = await _firestore.doc('users/$uid').get();
      profile = Profile.fromSnapshot(snapshot);

      logger.i('ProfileService - fetchProfile is successful\n$uid');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('ProfileService - fetchProfile failed $error');
      SentryUtil.error('ProfileService.fetchProfile() error!',
          'ProfileService class', error, stackTrace);
    }

    return Response(data: profile, hasError: hasError);
  }

  @override
  Future<Response<String>> updateProfile(Profile profile) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid');

      var requestBody = profile.toJson();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(requestBody);

      data = docRef.id;
      logger.i('ProfileService - updateProfile is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('ProfileService - updateProfile failed\n$error\n$stackTrace');
      SentryUtil.error('ProfileService.updateProfile() error: Profile $profile',
          'ProfileService class', error, stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<void> setNotificationSetting(
    bool isNotificationsOn, {
    String? deviceToken,
  }) async {
    final batch = _firestore.batch();
    try {
      final userRef = _firestore.doc('users/${_authService.uid}');

      batch.update(userRef, {
        'isNotificationsOn': isNotificationsOn,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (deviceToken != null) {
        final userDoc = await userRef.get();

        var deviceTokens = userDoc.get('deviceTokens') ?? [];

        deviceTokens.removeWhere((token) => token['token'] == deviceToken);

        batch.update(userRef, {
          'deviceTokens': deviceTokens,
        });
      }

      await batch.commit();

      logger.i(
          'ProfileService - Updating user notification setting\n${_authService.uid}');
    } catch (error, stackTrace) {
      logger.e(
          'ProfileService - Updating user notification setting failed\n$error');
      SentryUtil.error(
          'ProfileService.setNotificationSetting() error: isNotificationsOn $isNotificationsOn, deviceToken $deviceToken',
          'ProfileService class',
          error,
          stackTrace);
    }
  }

  @override
  Stream<List<Profile>> getOrgProfilesStreams() {
    Stream<List<Profile>> profileListStream = Stream.value([]);
    List<Profile> profileList = [];
    final uid = _authService.uid;
    try {
      profileListStream = _firestore
          .collection('users')
          .where('organizationId', isEqualTo: uid)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          profileList =
              snapshot.docs.map((doc) => Profile.fromSnapshot(doc)).toList();
        }
        return profileList;
      });
      logger.i('ProfileService - getOrgProfilesStreams is successful');
    } catch (error, stackTrace) {
      logger.e(
          'ProfileService - getOrgProfilesStreams failed\n$error\n$stackTrace');
      SentryUtil.error('ProfileService.getOrgProfilesStreams() error!',
          'ProfileService class', error, stackTrace);
    }

    return profileListStream;
  }

  @override
  Stream<Organization> getOrgStream() {
    Stream<Organization> organizationStream = Stream.value(Organization());
    final uid = _authService.uid;
    try {
      organizationStream = _firestore
          .doc('users/$uid')
          .snapshots()
          .map((snapshot) => Organization.fromSnapshot(snapshot));
      logger.i('ProfileService - getOrgStream is successful');
    } catch (error, stackTrace) {
      logger.e('ProfileService - getOrgStream failed\n$error\n$stackTrace');
      SentryUtil.error('ProfileService.getOrgStream() error!',
          'ProfileService class', error, stackTrace);
    }
    return organizationStream;
  }

  @override
  Future<Response<Organization>> fetchOrg() async {
    Organization? organization;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final snapshot = await _firestore.doc('users/$uid').get();
      organization = Organization.fromSnapshot(snapshot);

      logger.i('ProfileService - fetchOrg is successful\n$uid');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('ProfileService - fetchOrg failed $error');
      SentryUtil.error('ProfileService.fetchOrg() error!',
          'ProfileService class', error, stackTrace);
    }

    return Response(data: organization, hasError: hasError);
  }

  @override
  Future<Response<Count?>> fetchLatestCount(String userId) async {
    Count? count;

    var hasError = false;

    try {
      final snapshot = await _firestore
          .collection('users/$userId/counts')
          .where('state', isEqualTo: 'complete')
          .where('deleted', isEqualTo: false)
          .orderBy('sortKey')
          .limit(1)
          .get();
      if (snapshot.size != 0) {
        count = Count.fromSnapshot(snapshot.docs.first);
      }
      logger.i('ProfileService - fetchLatestCount is successful ${count?.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('ProfileService - fetchLatestCount failed\n$error\n$stackTrace');
      SentryUtil.error(
          'ProfileService.fetchLatestCount() error: userId $userId',
          'ProfileService class',
          error,
          stackTrace);
    }

    return Response<Count?>(
      data: count,
      hasError: hasError,
    );
  }
}

class MockProfileService implements ProfileService {
  @override
  Future<Response<Profile>> fetchProfile() {
    return Future.value(
      Response<Profile>(
        data: Profile(),
      ),
    );
  }

  @override
  Stream<Profile> getProfileStream() {
    return Stream.value(Profile());
  }

  @override
  Future<Response<String>> updateProfile(Profile profile) {
    return Future.value(Response<String>(data: ''));
  }

  @override
  Future<void> setNotificationSetting(bool isNotificationsOn,
      {String? deviceToken}) {
    return Future<Response>.value(Response(hasError: false));
  }

  @override
  Stream<List<Profile>> getOrgProfilesStreams() {
    return Stream.value(<Profile>[]);
  }

  @override
  Stream<Organization> getOrgStream() {
    return Stream.value(Organization());
  }

  @override
  Future<Response<Organization>> fetchOrg() async {
    return Future.value(
      Response<Organization>(
        data: Organization(),
      ),
    );
  }

  @override
  Future<Response<Count?>> fetchLatestCount(String userId) {
    return Future.value(
      Response<Count>(
        data: Count(),
      ),
    );
  }
}
