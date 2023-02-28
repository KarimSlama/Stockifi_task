import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/item_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';

void main() {
  late FirebaseFirestore firestore;
  late FirebaseAuth firebaseAuth;
  late AuthService authService;
  late ItemService itemService;

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
    // An ItemService instance with a fake Firestore instance and AuthService instance
    itemService = ItemServiceImpl(
      firestore: firestore,
      authService: authService,
    );
  });

  test('Item should be created', () async {
    // GIVEN
    // An Item instance with the following parameters
    final item = Item(
      unit: 'ml',
      type: 'Cider',
      variety: 'Cider',
      size: 750,
      cost: 10,
    );

    // WHEN
    // createItem() is called
    final response = await itemService.createItem(item);

    // THEN
    // itemId should not be null
    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Unit Test Item 1 should be created', () async {
    // GIVEN
    // An Item instance with the following parameters
    final item = Item(
      name: 'Unit Test Item 1',
      unit: 'ml',
      type: 'Cider',
      variety: 'Cider',
      size: 750,
      cost: 10,
    );

    // WHEN
    // createItem() is called
    final response = await itemService.createItem(item);
    final createdItem =
        await itemService.getSingleItemById(response.data!).first;

    // THEN
    expect(createdItem.name, 'Unit Test Item 1');
    expect(createdItem.unit, 'ml');
    expect(createdItem.type, 'Cider');
    expect(createdItem.variety, 'Cider');
    expect(createdItem.size, 750);
    expect(createdItem.cost, 10);
  });
  test('Created Item properties before and after firestore create are the same',
      () async {
    // GIVEN
    // An Item instance with the following parameters
    final item = Item(
      name: 'Unit Test Item 1',
      unit: 'ml',
      type: 'Cider',
      variety: 'Cider',
      size: 750,
      cost: 10,
    );

    // WHEN
    // createItem() is called
    final response = await itemService.createItem(item);
    final createdItem =
        await itemService.getSingleItemById(response.data!).first;

    // THEN
    //copy only properties set by fake firestore
    final newItem = item.copyWith(
      id: createdItem.id,
      createdAt: createdItem.createdAt,
      updatedAt: createdItem.updatedAt,
      starred: createdItem.starred,
    );

    expect(createdItem, newItem);
  });

  test('Item should be updated', () async {
    // GIVEN
    // A created Item instance
    final item = Item(
      unit: 'ml',
      type: 'Cider',
      variety: 'Cider',
      size: 750,
      cost: 10,
    );

    final createdItem = await itemService.createItem(item);

    // And a new Item instance with updated fields
    final newItem = Item(
      id: createdItem.data,
      unit: 'ml',
      type: 'Cider',
      variety: 'Cider',
      size: 750,
      cost: 200,
    );

    // WHEN
    // updateItem() is called
    final response = await itemService.updateItem(newItem);

    // THEN
    // updatedItemId should not be null
    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Updated Item Name should be "Updated Unit Test Item 1"', () async {
    // GIVEN
    // An Item instance with the following parameters
    final item = Item(
      name: 'Unit Test Item 1',
      unit: 'ml',
      type: 'Cider',
      variety: 'Cider',
      size: 750,
      cost: 10,
    );

    // WHEN
    // createItem() is called
    final responseCreate = await itemService.createItem(item);
    final createdItem =
        await itemService.getSingleItemById(responseCreate.data!).first;

    final newItem = createdItem.copyWith(name: 'Updated Unit Test Item 1');

    final responseUpdate = await itemService.updateItem(newItem);
    final updatedItem =
        await itemService.getSingleItemById(responseUpdate.data!).first;

    expect(updatedItem.name, 'Updated Unit Test Item 1');
  });

  test('Updated Item Cost should be 1234', () async {
    // GIVEN
    // An Item instance with the following parameters
    final item = Item(
      name: 'Unit Test Item 1',
      unit: 'ml',
      type: 'Cider',
      variety: 'Cider',
      size: 750,
      cost: 10,
    );

    // WHEN
    // createItem() is called
    final responseCreate = await itemService.createItem(item);
    final createdItem =
        await itemService.getSingleItemById(responseCreate.data!).first;

    final newItem = createdItem.copyWith(cost: 1234);

    final responseUpdate = await itemService.updateItem(newItem);
    final updatedItem =
        await itemService.getSingleItemById(responseUpdate.data!).first;

    expect(updatedItem.cost, 1234);
  });
  test('Item should be soft deleted', () async {
    // GIVEN
    // A created Item instance
    final item = Item(
      unit: 'ml',
      type: 'Cider',
      variety: 'Cider',
      size: 750,
      cost: 10,
    );

    final createdItem = await itemService.createItem(item);

    // WHEN
    // updateItemDeletedStatus() is called
    final response = await itemService
        .updateItemDeletedStatus(item.copyWith(id: createdItem.data));

    // THEN
    // deletedItemId should not be null
    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
}
