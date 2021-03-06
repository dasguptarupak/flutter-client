import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/document/document_actions.dart';
import 'package:invoiceninja_flutter/redux/invoice/invoice_actions.dart';
import 'package:invoiceninja_flutter/ui/app/dialogs/error_dialog.dart';
import 'package:invoiceninja_flutter/ui/app/snackbar_row.dart';
import 'package:invoiceninja_flutter/ui/invoice/view/invoice_view.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:redux/redux.dart';

class InvoiceViewScreen extends StatelessWidget {
  const InvoiceViewScreen({
    Key key,
    this.isFilter = false,
  }) : super(key: key);
  final bool isFilter;
  static const String route = '/invoice/view';

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, InvoiceViewVM>(
      converter: (Store<AppState> store) {
        return InvoiceViewVM.fromStore(store);
      },
      builder: (context, viewModel) {
        return InvoiceView(
          viewModel: viewModel,
          isFilter: isFilter,
        );
      },
    );
  }
}

class EntityViewVM {
  EntityViewVM({
    @required this.state,
    @required this.company,
    @required this.invoice,
    @required this.client,
    @required this.isSaving,
    @required this.isDirty,
    @required this.onActionSelected,
    @required this.onUploadDocument,
    @required this.onDeleteDocument,
    @required this.onEditPressed,
    @required this.onPaymentsPressed,
    @required this.onRefreshed,
    @required this.onViewExpense,
  });

  final AppState state;
  final CompanyEntity company;
  final InvoiceEntity invoice;
  final ClientEntity client;
  final bool isSaving;
  final bool isDirty;
  final Function(BuildContext, EntityAction) onActionSelected;
  final Function(BuildContext, [int]) onEditPressed;
  final Function(BuildContext) onPaymentsPressed;
  final Function(BuildContext) onRefreshed;
  final Function(BuildContext, String) onUploadDocument;
  final Function(BuildContext, DocumentEntity) onDeleteDocument;
  final Function(BuildContext, DocumentEntity) onViewExpense;
}

class InvoiceViewVM extends EntityViewVM {
  InvoiceViewVM({
    AppState state,
    CompanyEntity company,
    InvoiceEntity invoice,
    ClientEntity client,
    bool isSaving,
    bool isDirty,
    Function(BuildContext, EntityAction) onEntityAction,
    Function(BuildContext, [int]) onEditPressed,
    Function(BuildContext, [bool]) onClientPressed,
    Function(BuildContext, [bool]) onUserPressed,
    Function(BuildContext, PaymentEntity, [bool]) onPaymentPressed,
    Function(BuildContext) onPaymentsPressed,
    Function(BuildContext) onRefreshed,
    Function(BuildContext, String) onUploadDocument,
    Function(BuildContext, DocumentEntity) onDeleteDocument,
    Function(BuildContext, DocumentEntity) onViewExpense,
  }) : super(
            state: state,
            company: company,
            invoice: invoice,
            client: client,
            isSaving: isSaving,
            isDirty: isDirty,
            onActionSelected: onEntityAction,
            onEditPressed: onEditPressed,
            onPaymentsPressed: onPaymentsPressed,
            onRefreshed: onRefreshed,
            onUploadDocument: onUploadDocument,
            onDeleteDocument: onDeleteDocument,
            onViewExpense: onViewExpense);

  factory InvoiceViewVM.fromStore(Store<AppState> store) {
    final state = store.state;
    final invoice = state.invoiceState.get(state.invoiceUIState.selectedId);
    final client = state.clientState.get(invoice.clientId);

    Future<Null> _handleRefresh(BuildContext context) {
      final completer = snackBarCompleter<Null>(
          context, AppLocalization.of(context).refreshComplete);
      store.dispatch(LoadInvoice(completer: completer, invoiceId: invoice.id));
      return completer.future;
    }

    return InvoiceViewVM(
      state: state,
      company: state.company,
      isSaving: state.isSaving,
      isDirty: invoice.isNew,
      invoice: invoice,
      client: client,
      onEditPressed: (BuildContext context, [int index]) {
        editEntity(
            context: context,
            entity: invoice,
            subIndex: index,
            completer: snackBarCompleter<ClientEntity>(
                context, AppLocalization.of(context).updatedInvoice));
      },
      onRefreshed: (context) => _handleRefresh(context),
      onPaymentsPressed: (BuildContext context) {
        viewEntitiesByType(
            context: context,
            entityType: EntityType.payment,
            filterEntity: invoice);
      },
      onEntityAction: (BuildContext context, EntityAction action) =>
          handleInvoiceAction(context, [invoice], action),
      onUploadDocument: (BuildContext context, String filePath) {
        final Completer<DocumentEntity> completer = Completer<DocumentEntity>();
        store.dispatch(SaveInvoiceDocumentRequest(
            filePath: filePath, invoice: invoice, completer: completer));
        completer.future.then((client) {
          Scaffold.of(context).showSnackBar(SnackBar(
              content: SnackBarRow(
            message: AppLocalization.of(context).uploadedDocument,
          )));
        }).catchError((Object error) {
          showDialog<ErrorDialog>(
              context: context,
              builder: (BuildContext context) {
                return ErrorDialog(error);
              });
        });
      },
      onDeleteDocument: (BuildContext context, DocumentEntity document) {
        final completer = snackBarCompleter<Null>(
            context, AppLocalization.of(context).deletedDocument);
        completer.future.then<Null>(
            (value) => store.dispatch(LoadInvoice(invoiceId: invoice.id)));
        store.dispatch(DeleteDocumentRequest(completer, [document.id]));
      },
      onViewExpense: (BuildContext context, DocumentEntity document) {
        /*
        viewEntityById(
            context: context,
            entityId: document.expenseId,
            entityType: EntityType.expense);
         */
      },
    );
  }
}
