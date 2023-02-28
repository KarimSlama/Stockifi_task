import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/models/recipe.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';
import 'package:stocklio_flutter/services/recipe_service.dart';

void main() {
  late FirebaseFirestore firestore;
  late FirebaseAuth firebaseAuth;
  late AuthService authService;
  late RecipeService recipeService;

  setUp(() async {
    // A FakeFirebaseFirestore instance
    firestore = FakeFirebaseFirestore();
    // A MockFirebaseAuth instance
    firebaseAuth = MockFirebaseAuth();

    // Mocks of admin service and organization service
    final adminService = MockAdminService();
    final organizationService = MockOrganizationService();

    // An AuthService instance with a fake Firestore instance
    authService = AuthServiceImpl(
      firebaseAuth: firebaseAuth,
      adminService: adminService,
      organizationService: organizationService,
    );
    // An RecipeService instance with a fake Firestore instance and AuthService instance
    recipeService = RecipeServiceImpl(
      authService: authService,
      firestore: firestore,
    );
  });

  test('Recipe should be created from recipe service', () async {
    final response = await recipeService.createRecipe(Recipe());

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Recipe should be updated from recipe service', () async {
    final createdRecipe = await recipeService.createRecipe(Recipe());

    final response = await recipeService
        .updateRecipe(Recipe(id: createdRecipe.data, name: 'new name'));

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Recipe should be soft deleted from recipe service', () async {
    final createdRecipe = await recipeService.createRecipe(Recipe());

    final response = await recipeService.softDeleteRecipe(createdRecipe.data!);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
}
