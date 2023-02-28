import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/app_config_service.dart';
import 'package:stocklio_flutter/services/helper/stream_subscription_helper.dart';
import 'package:stocklio_flutter/services/item_transfer_service.dart';
import 'package:stocklio_flutter/services/notification_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';
import 'package:stocklio_flutter/services/shortcut_service.dart';
import 'package:stocklio_flutter/services/tag_service.dart';
import 'package:stocklio_flutter/services/task_service.dart';
import 'package:stocklio_flutter/services/wastage_item_service.dart';
import 'package:stocklio_flutter/services/wastage_service.dart';
import 'package:stocklio_flutter/services/tutorial_service.dart';

import './services/count_area_service.dart';
import './services/count_item_service.dart';
import './services/count_service.dart';
import './services/file_uploader_service.dart';
import './services/global_item_service.dart';
import './services/invoice_service.dart';
import './services/item_service.dart';
import './services/pos_item_service.dart';
import './services/profile_service.dart';
import './services/recipe_service.dart';
import './services/auth_service.dart';
import './services/supplier_service.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  getIt.registerSingleton<AdminService>(AdminServiceImpl());
  getIt.registerSingleton<OrganizationService>(OrganizationServiceImpl());
  getIt.registerSingleton<AuthService>(AuthServiceImpl());
  getIt.registerSingleton<FileUploaderService>(FileUploaderServiceImpl());
  getIt.registerSingleton<CountAreaService>(CountAreaServiceImpl());
  getIt.registerSingleton<CountItemService>(CountItemServiceImpl());
  getIt.registerSingleton<CountService>(CountServiceImpl());
  getIt.registerSingleton<GlobalItemService>(GlobalItemServiceImpl());
  getIt.registerSingleton<InvoiceService>(InvoiceServiceImpl());
  getIt.registerSingleton<ItemService>(ItemServiceImpl());
  getIt.registerSingleton<PosItemService>(PosItemServiceImpl());
  getIt.registerSingleton<ProfileService>(ProfileServiceImpl());
  getIt.registerSingleton<RecipeService>(RecipeServiceImpl());
  getIt.registerSingleton<SupplierService>(SupplierServiceImpl());
  getIt.registerSingleton<NotificationService>(NotificationServiceImpl());
  getIt.registerSingleton<TaskService>(TaskServiceImpl());
  getIt.registerSingleton<TutorialService>(TutorialServiceImpl());
  getIt.registerSingleton<ShortcutService>(ShortcutServiceImpl());
  getIt.registerSingleton<AppConfigService>(AppConfigServiceImpl());
  getIt.registerSingleton<StreamSubscriptionHelper>(StreamSubscriptionHelper());
  getIt.registerSingleton<WastageItemService>(WastageItemServiceImpl());
  getIt.registerSingleton<WastageService>(WastageServiceImpl());
  getIt.registerSingleton<TagService>(TagServiceImpl());
  getIt.registerSingleton<ItemTransferService>(ItemTransferServiceImpl());
}
