// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../models/recipe.dart';

// Services
import 'auth_service.dart';

// Utils
import '../utils/logger_util.dart';

abstract class RecipeService {
  Stream<List<Recipe>> getRecipesStream({
    bool isFetchingDeleted = false,
    bool isFetchingArchived = false,
  });
  Future<Response<String?>> createRecipe(Recipe recipe);
  Future<Response<String?>> updateRecipe(Recipe recipe);
  Future<Response<String?>> softDeleteRecipe(String recipeId);
  Future<Response<String?>> setArchived(String recipeId, bool value);
}

class RecipeServiceImpl implements RecipeService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;

  RecipeServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }
  @override
  Stream<List<Recipe>> getRecipesStream({
    bool isFetchingDeleted = false,
    bool isFetchingArchived = false,
  }) {
    final uid = _authService.uid;
    return _firestore
        .collection('users/$uid/recipes')
        .where('deleted', isEqualTo: isFetchingDeleted)
        .where('archived', isEqualTo: isFetchingArchived)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          return Recipe.fromSnapshot(doc);
        }).toList();
      }
      return <Recipe>[];
    });
  }

  @override
  Future<Response<String?>> createRecipe(Recipe recipe) async {
    String? data;
    var hasError = false;

    // final recipePrecise = toPreciseDecimal(recipe);

    try {
      final uid = _authService.uid;
      final docRef = _firestore.collection('users/$uid/recipes').doc();

      // var requestBody = recipePrecise.toJson();
      var requestBody = recipe.toJson();

      requestBody['createdAt'] = FieldValue.serverTimestamp();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = false;
      requestBody['id'] = docRef.id;

      await docRef.set(requestBody);
      data = docRef.id;

      logger.i('RecipeService - createRecipe is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('RecipeService - createRecipe failed\n$error\n$stackTrace');
      SentryUtil.error('RecipeService.createRecipe() error: Recipe $recipe',
          'RecipeProvider class', error, stackTrace);
    }
    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> updateRecipe(Recipe recipe) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/recipes/${recipe.id}');

      var requestBody = recipe.toJson();

      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(requestBody);

      data = docRef.id;
      logger.i('RecipeService - updateRecipe is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('RecipeService - updateRecipe failed\n$error\n$stackTrace');
      SentryUtil.error('RecipeService.updateRecipe() error: Recipe $recipe',
          'RecipeProvider class', error, stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> softDeleteRecipe(String recipeId) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/recipes/$recipeId');

      var requestBody = {
        'updatedAt': FieldValue.serverTimestamp(),
        'deleted': true,
      };

      await docRef.update(requestBody);

      data = docRef.id;
      logger.i('RecipeService - softDeleteRecipe is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('RecipeService - softDeleteRecipe failed\n$error\n$stackTrace');
      SentryUtil.error(
          'RecipeService.softDeleteRecipe() error: Recipe ID $recipeId',
          'RecipeService class',
          error,
          stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> setArchived(String recipeId, bool value) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/recipes/$recipeId');

      var requestBody = {
        'updatedAt': FieldValue.serverTimestamp(),
        'archived': value,
      };

      await docRef.update(requestBody);

      data = docRef.id;

      logger.i('RecipeService - setArchived is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('RecipeService - setArchived failed\n$error\n$stackTrace');

      SentryUtil.error(
        'RecipeService.setArchived() error: Recipe ID $recipeId',
        'RecipeService class',
        error,
        stackTrace,
      );
    }

    return Response(data: data, hasError: hasError);
  }
}

class MockRecipeService implements RecipeService {
  @override
  Future<Response<String?>> createRecipe(Recipe recipe) {
    return Future.value(Response(data: '1'));
  }

  @override
  Stream<List<Recipe>> getRecipesStream({
    bool isFetchingDeleted = false,
    bool isFetchingArchived = false,
  }) {
    return Stream.value([]);
  }

  @override
  Future<Response<String?>> softDeleteRecipe(String recipeId) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> updateRecipe(Recipe recipe) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> setArchived(String recipeId, bool value) {
    return Future.value(Response(data: '1'));
  }
}
