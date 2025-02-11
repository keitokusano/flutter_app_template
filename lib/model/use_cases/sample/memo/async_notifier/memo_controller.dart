import 'dart:async';

import 'package:flutter_app_template/utils/logger.dart';
import 'package:flutter_app_template/utils/provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../exceptions/app_exception.dart';
import '../../../../../extensions/exception_extension.dart';
import '../../../../entities/sample/memo.dart';
import '../../../../repositories/firebase_auth/firebase_auth_repository.dart';
import '../../../../repositories/firestore/collection_paging_repository.dart';
import '../../../../repositories/firestore/document.dart';
import '../../../../repositories/firestore/document_repository.dart';
import '../../typedef.dart';
import '../memo_controller.dart' as memo_state_notifier;

/// AsyncNotifier & 非同期操作の結果を同期的に扱うサンプルコード
final memoProvider =
    AsyncNotifierProvider<MemoController, List<Memo>>(MemoController.new);

class MemoController extends AsyncNotifier<List<Memo>> {
  @override
  FutureOr<List<Memo>> build() async {
    /// ログアウト等でauthStateの状態が更新されたら発火されて新しいインスタンスを生成する
    ref.watch(authStateProvider);

    final userId = _firebaseAuthRepository.loggedInUserId;
    if (userId == null) {
      return [];
    }
    _collectionPagingRepository = ref.read(
      memoPagingProvider(
        CollectionParam<Memo>(
          query: Document.colRef(
            Memo.collectionPath(userId),
          ).orderBy('createdAt', descending: true),
          limit: 20,
          decode: Memo.fromJson,
        ),
      ),
    );
    final repository = _collectionPagingRepository!;
    final data = await repository.fetch(
      fromCache: (cache) {
        /// キャッシュから即時反映する
        state = AsyncData(
          cache.map((e) => e.entity).whereType<Memo>().toList(),
        );
      },
    );
    return data.map((e) => e.entity).whereType<Memo>().toList();
  }

  FirebaseAuthRepository get _firebaseAuthRepository =>
      ref.read(firebaseAuthRepositoryProvider);

  DocumentRepository get _documentRepository =>
      ref.read(documentRepositoryProvider);

  CollectionPagingRepository<Memo>? _collectionPagingRepository;

  /// ページング取得
  Future<ErrorMessage?> onFetchMore() async {
    try {
      final repository = _collectionPagingRepository;
      if (repository == null) {
        throw AppException.irregular();
      }

      final data = await repository.fetchMore();
      if (data.isNotEmpty) {
        state = AsyncData([
          ...state.value ?? [],
          ...data.map((e) => e.entity).whereType<Memo>(),
        ]);
      }
      return null;
    } on Exception catch (e) {
      logger.shout(e);
      return e.errorMessage;
    }
  }

  /// 作成
  Future<ErrorMessage?> onCreate(String text) async {
    try {
      final userId = _firebaseAuthRepository.loggedInUserId;
      if (userId == null) {
        throw AppException(title: 'ログインしてください');
      }

      final docRef = Document.docRef(Memo.collectionPath(userId));
      final now = DateTime.now();
      final data = Memo(
        memoId: docRef.id,
        text: text,
        createdAt: now,
        updatedAt: now,
      );
      await _documentRepository.save(
        Memo.docPath(userId, docRef.id),
        data: data.toCreateDoc,
      );
      state = AsyncData([data, ...state.value ?? []]);

      /// 同じデータソースを参照しているproviderでデータの再取得させるためにProviderを再生成する
      /// refreshと違い、該当するprovider参照されたタイミングでインスタンスを再生成する
      ref.invalidate(memo_state_notifier.memoProvider);
      return null;
    } on AppException catch (e) {
      logger.shout(e);

      return e.errorMessage;
    }
  }

  /// 更新
  Future<ErrorMessage?> onUpdate(Memo memo) async {
    try {
      final userId = _firebaseAuthRepository.loggedInUserId;
      if (userId == null) {
        throw AppException(title: 'ログインしてください');
      }
      final value = state.value ?? [];
      if (value.isEmpty) {
        throw AppException(title: '更新できません');
      }
      final docId = memo.memoId;
      if (docId == null) {
        throw AppException.irregular();
      }
      final data = memo.copyWith(updatedAt: DateTime.now());
      await _documentRepository.update(
        Memo.docPath(userId, docId),
        data: data.toUpdateDoc,
      );
      state = AsyncData(
        value
            .map(
              (e) => e.memoId == memo.memoId ? memo : e,
            )
            .toList(),
      );

      /// 同じデータソースを参照しているproviderでデータの再取得させるためにProviderを再生成する
      /// refreshと違い、該当するprovider参照されたタイミングでインスタンスを再生成する
      ref.invalidate(memo_state_notifier.memoProvider);
      return null;
    } on Exception catch (e) {
      logger.shout(e);
      return e.errorMessage;
    }
  }

  /// 削除
  Future<ErrorMessage?> onRemove(String docId) async {
    try {
      final userId = _firebaseAuthRepository.loggedInUserId;
      if (userId == null) {
        throw AppException(title: 'ログインしてください');
      }
      final value = state.value ?? [];
      if (value.isEmpty) {
        throw AppException(title: '削除できません');
      }
      await _documentRepository.remove(Memo.docPath(userId, docId));
      state = AsyncData(
        value
            .where(
              (e) => e.memoId != docId,
            )
            .toList(),
      );

      /// 同じデータソースを参照しているproviderでデータの再取得させるためにProviderを再生成する
      /// refreshと違い、該当するprovider参照されたタイミングでインスタンスを再生成する
      ref.invalidate(memo_state_notifier.memoProvider);
      return null;
    } on Exception catch (e) {
      logger.shout(e);
      return e.errorMessage;
    }
  }
}
