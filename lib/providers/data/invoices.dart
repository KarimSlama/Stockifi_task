// Dart Packages
import 'dart:async';

// Flutter Packages
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import 'package:uuid/uuid.dart';

// Models
import '../../models/invoice.dart';

// Services
import '../../services/invoice_service.dart';

class InvoiceProvider with ChangeNotifier {
  late InvoiceService _invoiceService;

  InvoiceProvider({
    InvoiceService? invoiceService,
  }) {
    _invoiceService = invoiceService ?? GetIt.instance<InvoiceService>();
  }

  // States
  List<Invoice> _invoices = [];
  StreamSubscription<List<Invoice>>? _invoiceStreamSub;
  bool _isLoading = true;
  bool _isInit = false;

  // Getters
  List<Invoice> get invoices {
    _invoiceStreamSub ?? _listenToInvoicesStream();
    return [..._invoices];
  }

  bool get isLoading => _isLoading;

  Future<void>? cancelStreamSubscriptions() {
    return _invoiceStreamSub?.cancel();
  }

  Stream<List<Invoice>> get invoicesStream =>
      _invoiceService.getInvoicesStream();

  void _listenToInvoicesStream() {
    final invoicesStream = _invoiceService.getInvoicesStream();
    _invoiceStreamSub = invoicesStream.listen((List<Invoice> invoices) {
      final unresolvedInvoices =
          invoices.where((e) => e.state != 'resolved').toList()
            ..sort((x, y) {
              final dateX = x.createdAt ?? DateTime.now();
              final dateY = y.createdAt ?? DateTime.now();
              return dateY.compareTo(dateX);
            });

      final resolvedInvoices =
          invoices.where((e) => e.state == 'resolved').toList()
            ..sort((x, y) {
              final dateX = x.deliveryDate ?? DateTime.now();
              final dateY = y.deliveryDate ?? DateTime.now();
              return dateY.compareTo(dateX);
            });

      _invoices = [...unresolvedInvoices, ...resolvedInvoices];

      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  Invoice findById(String id) =>
      _invoices.firstWhere((invoice) => invoice.id == id);

  Future<void> createInvoice(
    Invoice invoice, {
    List<Uint8List>? newImagesToUpload,
  }) async {
    try {
      final tempId = const Uuid().v1();

      _invoices.insert(0, invoice.copyWith(id: tempId, state: 'loading'));
      notifyListeners();

      final response = await _invoiceService.createInvoice(
        invoice,
        newImagesToUpload: newImagesToUpload!,
      );

      _invoices.removeWhere((element) => element.id == tempId);

      logger
          .i('InvoiceProvider - createInvoice is successful ${response.data}');
    } catch (error, stackTrace) {
      logger.e('InvoiceProvider - createInvoice failed\n$error\n$stackTrace');
      SentryUtil.error(
          'InvoiceProvider.createInvoice error: Invoice $invoice, List<Uint8List> $newImagesToUpload',
          'InvoiceProvider class',
          error,
          stackTrace);
    }
  }

  Future<void> updateInvoice(
    Invoice invoice, {
    List<Uint8List>? newImagesToUpload,
  }) async {
    try {
      if (newImagesToUpload?.isNotEmpty ?? false) {
        final index =
            _invoices.indexWhere((element) => element.id == invoice.id);
        var tempFiles = [..._invoices[index].files!];
        tempFiles.addAll(List.filled(newImagesToUpload!.length, 'loading'));
        notifyListeners();
      }

      await _invoiceService.updateInvoice(
        invoice,
        newImagesToUpload: newImagesToUpload ?? [],
      );
      logger.i('InvoiceProvider - updateInvoice is successful ${invoice.id}');
    } catch (error, stackTrace) {
      logger.e('InvoiceProvider - updateInvoice failed\n$error\n$stackTrace');
      SentryUtil.error(
          'InvoiceProvider.updateInvoice error: Invoice $invoice, List<Uint8List> $newImagesToUpload',
          'InvoiceProvider class',
          error,
          stackTrace);
    }
  }

  Future<void> addInvoiceComment(String invoiceId, String comment) async {
    try {
      await _invoiceService.addInvoiceComment(invoiceId, comment);
      logger.i('InvoiceProvider - addInvoiceComment is successful $invoiceId');
    } catch (error, stackTrace) {
      logger
          .e('InvoiceProvider - addInvoiceComment failed\n$error\n$stackTrace');
      SentryUtil.error(
          'InvoiceProvider.addInvoiceComment error: Invoice ID $invoiceId, Comment $comment',
          'InvoiceProvider class',
          error,
          stackTrace);
    }
  }

  Future<void> deleteInvoiceImage(String invoiceId, String imageUrl) async {
    try {
      await _invoiceService.deleteInvoiceImage(invoiceId, imageUrl);
      logger.i('InvoiceProvider - deleteInvoiceImage is successful $invoiceId');
    } catch (error, stackTrace) {
      logger.e(
          'InvoiceProvider - deleteInvoiceImage failed\n$error\n$stackTrace');
      SentryUtil.error(
          'InvoiceProvider.deleteInvoiceImage error: Invoice ID $invoiceId, imageUrl $imageUrl',
          'InvoiceProvider class',
          error,
          stackTrace);
    }
  }

  Future<void> softDeleteInvoice(String invoiceId, [String? imageUrl]) async {
    try {
      await _invoiceService.softDeleteInvoice(invoiceId, imageUrl);
      logger.i('InvoiceProvider - softDeleteInvoice is successful $invoiceId');
    } catch (error, stackTrace) {
      logger
          .e('InvoiceProvider - softDeleteInvoice failed\n$error\n$stackTrace');
      SentryUtil.error(
          'InvoiceProvider.softDeleteInvoice error: Invoice ID $invoiceId, imageUrl $imageUrl',
          'InvoiceProvider class',
          error,
          stackTrace);
    }
  }

  void toggleIsLoading() {
    _isLoading = !_isLoading;
    notifyListeners();
  }

  // UI State
  Map<String, bool> expandedInvoices = {};

  bool getIsResolvedInvoiceExpanded(String invoiceId) =>
      expandedInvoices[invoiceId] ?? false;

  void toggleResolvedInvoiceExpanded(String invoiceId) {
    if (expandedInvoices.containsKey(invoiceId)) {
      expandedInvoices[invoiceId] = !(expandedInvoices[invoiceId] ?? true);
    } else {
      expandedInvoices.putIfAbsent(invoiceId, () => true);
    }
    notifyListeners();
  }

  // Invoice comments state preservation
  final unsavedComments = <String, String>{};

  void editUnsavedComment(String id, String comment) {
    unsavedComments[id] = comment;
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }
}

class InvoiceUIProvider extends ChangeNotifier {
  double scrollPosition = 0.0;
  bool isPressed = false;

  void setScrollPosition(double key) {
    scrollPosition = key;
  }

  void setIsPressed(bool value) {
    isPressed = value;
    notifyListeners();
  }
}
