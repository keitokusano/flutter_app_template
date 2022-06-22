import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../entities/sample/github/user.dart';
import '../../../repositories/api/github_api/github_api_repository.dart';

final githubUsersControllerProvider = StateNotifierProvider.autoDispose<
    GithubUsersController, AsyncValue<List<User>>>((ref) {
  return GithubUsersController(ref.read);
});

class GithubUsersController extends StateNotifier<AsyncValue<List<User>>> {
  GithubUsersController(
    this._read,
  ) : super(const AsyncValue.loading());

  final Reader _read;

  int _pageOffset = 0;
  bool _loading = false;
  final _pageCount = 20;

  GithubApiRepository get _githubApiRepository =>
      _read(githubApiRepositoryProvider);

  /// 一覧取得
  Future<void> fetch() async {
    if (_loading) {
      return;
    }
    _loading = true;

    _pageOffset = 0;

    final result = await AsyncValue.guard(() async {
      final data = await _githubApiRepository.fetchUsers(
        since: _pageOffset,
        perPage: _pageCount,
      );
      if (data.isNotEmpty) {
        _pageOffset = data.length;
      }
      return data;
    });

    _loading = false;
    state = result;
  }

  /// ページング取得
  Future<void> fetchMore() async {
    if (_loading) {
      return;
    }
    _loading = true;

    final result = await AsyncValue.guard(() async {
      final data = await _githubApiRepository.fetchUsers(
        since: _pageOffset,
        perPage: _pageCount,
      );
      if (data.isNotEmpty) {
        _pageOffset += data.length;
      }
      final value = state.value ?? [];
      return [...value, ...data];
    });

    _loading = false;
    state = result;
  }
}
