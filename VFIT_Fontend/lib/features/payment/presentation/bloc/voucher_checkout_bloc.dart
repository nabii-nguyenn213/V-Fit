import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_error_mapper.dart';
import '../../../../core/error/crash_reporter.dart';
import '../../data/models/payment_models.dart';
import '../../data/repositories/payment_repository.dart';

sealed class VoucherCheckoutEvent extends Equatable {
  const VoucherCheckoutEvent();

  @override
  List<Object?> get props => [];
}

class VoucherApplyRequested extends VoucherCheckoutEvent {
  const VoucherApplyRequested(this.voucherCode);

  final String voucherCode;

  @override
  List<Object?> get props => [voucherCode];
}

class VoucherCleared extends VoucherCheckoutEvent {
  const VoucherCleared();
}

class CheckoutRequested extends VoucherCheckoutEvent {
  const CheckoutRequested();
}

class VoucherCheckoutState extends Equatable {
  const VoucherCheckoutState({
    this.selectedVoucherCode,
    this.quote,
    this.checkoutResult,
    this.loading = false,
    this.errorMessage,
  });

  final String? selectedVoucherCode;
  final PaymentQuote? quote;
  final CheckoutResult? checkoutResult;
  final bool loading;
  final String? errorMessage;

  bool get hasVoucher => selectedVoucherCode != null;

  VoucherCheckoutState copyWith({
    String? selectedVoucherCode,
    PaymentQuote? quote,
    CheckoutResult? checkoutResult,
    bool? loading,
    String? errorMessage,
    bool clearVoucher = false,
    bool clearError = false,
  }) {
    return VoucherCheckoutState(
      selectedVoucherCode:
          clearVoucher ? null : selectedVoucherCode ?? this.selectedVoucherCode,
      quote: clearVoucher ? null : quote ?? this.quote,
      checkoutResult: checkoutResult ?? this.checkoutResult,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        selectedVoucherCode,
        quote,
        checkoutResult,
        loading,
        errorMessage,
      ];
}

class VoucherCheckoutBloc
    extends Bloc<VoucherCheckoutEvent, VoucherCheckoutState> {
  VoucherCheckoutBloc(this._repository) : super(const VoucherCheckoutState()) {
    on<VoucherApplyRequested>(_onApplyRequested);
    on<VoucherCleared>(_onCleared);
    on<CheckoutRequested>(_onCheckoutRequested);
  }

  final PaymentRepository _repository;

  Future<void> _onApplyRequested(
    VoucherApplyRequested event,
    Emitter<VoucherCheckoutState> emit,
  ) async {
    final voucherCode = event.voucherCode.trim().toUpperCase();
    if (voucherCode.isEmpty) {
      emit(state.copyWith(errorMessage: 'Vui lòng nhập mã voucher.'));
      return;
    }
    if (state.selectedVoucherCode != null &&
        state.selectedVoucherCode != voucherCode) {
      emit(
        state.copyWith(
          errorMessage:
              'Mỗi đơn hàng chỉ được áp dụng một voucher. Hãy bỏ mã hiện tại trước.',
        ),
      );
      return;
    }

    emit(state.copyWith(loading: true, clearError: true));
    try {
      final quote = await _repository.applyVoucher(voucherCode);
      emit(
        state.copyWith(
          selectedVoucherCode: quote.voucherCode ?? voucherCode,
          quote: quote,
          loading: false,
        ),
      );
    } catch (error, stackTrace) {
      await CrashReporter.record(error, stackTrace);
      emit(
        state.copyWith(
          loading: false,
          errorMessage: AppErrorMapper.friendlyMessage(error),
        ),
      );
    }
  }

  void _onCleared(
    VoucherCleared event,
    Emitter<VoucherCheckoutState> emit,
  ) {
    emit(state.copyWith(clearVoucher: true, clearError: true));
  }

  Future<void> _onCheckoutRequested(
    CheckoutRequested event,
    Emitter<VoucherCheckoutState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final result = await _repository.checkout(
        voucherCode: state.selectedVoucherCode,
      );
      emit(
        state.copyWith(
          checkoutResult: result,
          loading: false,
        ),
      );
    } catch (error, stackTrace) {
      await CrashReporter.record(error, stackTrace);
      emit(
        state.copyWith(
          loading: false,
          errorMessage: AppErrorMapper.friendlyMessage(error),
        ),
      );
    }
  }
}
