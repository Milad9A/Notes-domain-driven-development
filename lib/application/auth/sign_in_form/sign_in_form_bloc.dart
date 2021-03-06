import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:notes_ddd/domain/auth/auth_failure.dart';
import 'package:notes_ddd/domain/auth/i_auth_facade.dart';
import 'package:notes_ddd/domain/auth/value_objects.dart';

part 'sign_in_form_bloc.freezed.dart';
part 'sign_in_form_event.dart';
part 'sign_in_form_state.dart';

@injectable
class SignInFormBloc extends Bloc<SignInFormEvent, SignInFormState> {
  final IAuthFacade _authFacade;

  SignInFormBloc(this._authFacade) : super(SignInFormState.initial()) {
    on<SignInFormEvent>(
      (event, emit) async {
        event.map(
          emailChanged: (e) async* {
            emit(
              state.copyWith(
                emailAddress: EmailAddress(e.emailStr),
                authFailureOrSuccessOption: none(),
              ),
            );
          },
          passwordChanged: (e) async* {
            emit(
              state.copyWith(
                password: Password(e.passwordStr),
                authFailureOrSuccessOption: none(),
              ),
            );
          },
          registerWithEmailAndPasswordPressed: (e) async* {
            yield* _performActionOnAuthFacadeWithEmailAndPassword(
              _authFacade.registerWithEmailAndPassword,
            );
          },
          signWithEmailAndPasswordPressed: (e) async* {
            yield* _performActionOnAuthFacadeWithEmailAndPassword(
              _authFacade.signInWithEmailAndPassword,
            );
          },
          signWithGooglePressed: (e) async* {
            emit(
              state.copyWith(
                isSubmitting: true,
                authFailureOrSuccessOption: none(),
              ),
            );
            final failureOrSuccess = await _authFacade.signInWithGoogle();
            emit(
              state.copyWith(
                isSubmitting: false,
                authFailureOrSuccessOption: some(failureOrSuccess),
              ),
            );
          },
        );
      },
    );
  }

  Stream<SignInFormState> _performActionOnAuthFacadeWithEmailAndPassword(
    Future<Either<AuthFailure, Unit>> Function({
      required EmailAddress emailAddress,
      required Password password,
    })
        forwardedCall,
  ) async* {
    Either<AuthFailure, Unit>? failureOrSuccess;

    final isEmailValid = state.emailAddress.isValid();
    final isPasswordValid = state.password.isValid();

    if (isEmailValid && isPasswordValid) {
      yield state.copyWith(
        isSubmitting: true,
        authFailureOrSuccessOption: none(),
      );

      failureOrSuccess = await forwardedCall(
        emailAddress: state.emailAddress,
        password: state.password,
      );
    }
    yield state.copyWith(
      isSubmitting: false,
      showErrorMessages: true,
      authFailureOrSuccessOption: optionOf(failureOrSuccess),
    );
  }
}
