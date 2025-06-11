import 'package:flutter/material.dart';
import 'package:flutter_application_1/taskpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // 日付フォーマットのために追加

// HomePageウィジェットを定義。状態を持つためStatefulWidgetを使用
class HomePage extends StatefulWidget {
  const HomePage({super.key}); // コンストラクタ

  @override
  State<HomePage> createState() => _HomePageState();
}

// HomePageウィジェットの状態を管理するクラス
class _HomePageState extends State<HomePage> {
  // タスクのリストを定義。各タスクは「タイトル」「内容」「お気に入り状態」「作成日時」を持つMapとして保持
  List<Map<String, dynamic>> tasks = [];
  // 検索結果を表示するためのリスト
  List<Map<String, dynamic>> _filteredTasks = []; // ★追加
  // 検索キーワードを保持するためのコントローラー
  final TextEditingController _searchController =
      TextEditingController(); // ★追加

  // ★: ウィジェットが最初に作成されるときに呼び出される
  @override
  void initState() {
    super.initState();
    _loadTasks(); // ★: アプリ起動時に保存されたタスクを読み込む
    // 検索フィールドのテキスト変更をリッスン
    _searchController.addListener(_filterTasks); // ★追加
  }

  // ★: ウィジェットが破棄されるときに呼び出される
  @override
  void dispose() {
    // ★追加
    _searchController.removeListener(_filterTasks); // ★追加
    _searchController.dispose(); // ★追加
    super.dispose(); // ★追加
  }

  // ★: SharedPreferencesからタスクを読み込む非同期メソッド
  Future<void> _loadTasks() async {
    final prefs =
        await SharedPreferences.getInstance(); // SharedPreferencesのインスタンスを取得
    final String? tasksString =
        prefs.getString('tasks'); // 'tasks'というキーで保存されたJSON文字列を取得

    if (tasksString != null) {
      // JSON文字列をDartのList<dynamic>にデコード
      final List<dynamic> decodedTasks = json.decode(tasksString);
      setState(() {
        tasks = decodedTasks.map((item) {
          final taskMap = Map<String, dynamic>.from(item);
          // isFavoriteがnullの場合にfalseをデフォルト値として設定
          if (taskMap['isFavorite'] == null) {
            taskMap['isFavorite'] = false;
          }
          // createdAtがnullの場合に現在の時刻をデフォルト値として設定
          if (taskMap['createdAt'] == null) {
            taskMap['createdAt'] = DateTime.now().toIso8601String();
          }
          return taskMap;
        }).toList();
        _sortTasks(); // ★: ロード時にも並び替える
        _filterTasks(); // ★追加: ロード後、全タスクを表示するためにフィルタリングを実行
      });
    }
  }

  // ★: SharedPreferencesにタスクを保存する非同期メソッド
  Future<void> _saveTasks() async {
    final prefs =
        await SharedPreferences.getInstance(); // SharedPreferencesのインスタンスを取得
    // 現在のtasksリストをJSON形式の文字列にエンコードして保存
    await prefs.setString('tasks', json.encode(tasks));
  }

  // ★: タスクを並び替えるメソッド
  void _sortTasks() {
    setState(() {
      tasks.sort((a, b) {
        final bool isAFavorite = a['isFavorite'] ?? false;
        final bool isBFavorite = b['isFavorite'] ?? false;

        // お気に入りがtrueのものが優先されるようにソート
        if (isAFavorite && !isBFavorite) {
          return -1; // aがお気に入り、bがお気に入りでない → aを先に
        } else if (!isAFavorite && isBFavorite) {
          return 1; // bがお気に入り、aがお気に入りでない → bを先に
        } else {
          // 両方がお気に入り、または両方がお気に入りでない場合は作成日時でソート（新しいものが上）
          final DateTime? timeA =
              a['createdAt'] != null ? DateTime.parse(a['createdAt']) : null;
          final DateTime? timeB =
              b['createdAt'] != null ? DateTime.parse(b['createdAt']) : null;

          if (timeA != null && timeB != null) {
            return timeB.compareTo(timeA); // 新しいものを先頭にする
          } else if (timeA != null) {
            return -1; // timeAのみ存在するならtimeAを先頭に
          } else if (timeB != null) {
            return 1; // timeBのみ存在するならtimeBを先頭に
          }
          return 0; // 両方とも存在しない場合は順序を変えない
        }
      });
    });
  }

  // ★追加: タスクを検索・フィルタリングするメソッド
  void _filterTasks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTasks = List.from(tasks); // 検索ワードが空なら全タスクを表示
      } else {
        _filteredTasks = tasks.where((task) {
          final title = (task['title'] ?? '').toLowerCase();
          return title.contains(query); // タイトルに検索ワードが含まれるかチェック
        }).toList();
      }
    });
  }

// タスク追加ページへ遷移する非同期メソッド
  void _navigateToAddTaskPage() async {
    // TaskPageへ遷移し、戻り値（追加されたタスク情報）を待つ
    final result = await Navigator.push(
      context, // 現在のコンテキスト
      MaterialPageRoute(
          builder: (context) => const TaskPage()), // TaskPageへのルート
    );
    // resultがnullでなく、かつMap<String, String>型であることを確認
    if (result != null && result is Map<String, String>) {
      setState(() {
        // ★変更: 新しいタスクにはisFavorite: false と createdAt を追加
        tasks.add({
          'title': result['title']!,
          'description': result['description']!,
          'isFavorite': false, // 新規追加タスクはデフォルトでお気に入りではない
          'createdAt': DateTime.now().toIso8601String(), // 現在のタイムスタンプを追加
        });
      });
      _sortTasks(); // ★: タスク追加後にも並び替える
      _filterTasks(); // ★追加: タスク追加後、フィルタリングを再実行
      _saveTasks(); // ★: タスクが追加されたら、すぐに保存する
    }
  }

  // タスク編集ページへ遷移する非同期メソッド
  void _navigateToEditTaskPage(int index) async {
    // 表示されているリスト（_filteredTasks）のインデックスから、元のtasksリストのインデックスを特定
    // これは、検索結果のタスクを編集する際に元のタスクを正確に指すため
    final originalTask = _filteredTasks[index];
    final originalIndexInTasks = tasks.indexOf(originalTask);

    if (originalIndexInTasks == -1) return; // 見つからない場合は何もしない

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskPage(
          initialTitle: originalTask['title'] ?? '',
          initialDescription: originalTask['description'] ?? '',
        ),
      ),
    );
    if (result != null && result is Map<String, String>) {
      setState(() {
        // 既存のタスクのisFavorite状態とcreatedAt状態を保持しつつ更新
        tasks[originalIndexInTasks] = {
          // ★変更: tasksリストを更新
          'title': result['title']!,
          'description': result['description']!,
          'isFavorite': originalTask['isFavorite'] ?? false,
          'createdAt': originalTask['createdAt'], // 編集しても作成日時は変更しない
        };
      });
      _sortTasks(); // ★: タスク編集後にも並び替える
      _filterTasks(); // ★追加: タスク編集後、フィルタリングを再実行
      _saveTasks(); // ★: タスクが編集されたら、すぐに保存する
    }
  }

  // ★変更: お気に入り状態を切り替えるメソッド
  void _toggleFavorite(int index) {
    // 表示されているリスト（_filteredTasks）のインデックスから、元のtasksリストのインデックスを特定
    final originalTask = _filteredTasks[index];
    final originalIndexInTasks = tasks.indexOf(originalTask);

    if (originalIndexInTasks == -1) return; // 見つからない場合は何もしない

    setState(() {
      // isFavoriteの状態を反転させる
      tasks[originalIndexInTasks]['isFavorite'] =
          !(tasks[originalIndexInTasks]['isFavorite'] ?? false); // ★変更
    });
    _sortTasks(); // ★: お気に入り状態変更後にも並び替える
    _filterTasks(); // ★追加: お気に入り状態変更後、フィルタリングを再実行
    _saveTasks(); // ★: お気に入り状態変更を保存する
  }

  // ★変更: タスク削除メソッド
  void _deleteTask(int index) {
    // 表示されているリスト（_filteredTasks）のインデックスから、元のtasksリストのインデックスを特定
    final originalTask = _filteredTasks[index];
    final originalIndexInTasks = tasks.indexOf(originalTask);

    if (originalIndexInTasks == -1) return; // 見つからない場合は何もしない

    setState(() {
      tasks.removeAt(originalIndexInTasks); // ★変更
    });
    _filterTasks(); // ★追加: タスク削除後、フィルタリングを再実行
    _saveTasks(); // ★: タスクが削除されたら、すぐに保存する
  }

  @override
  Widget build(BuildContext context) {
    // 画面全体の基本的な構造を提供するScaffoldウィジェット
    return Scaffold(
      // アプリケーションバーの設定
      appBar: AppBar(
        title: const Text('Todoリスト'), // アプリバーのタイトル
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          // ★追加: 検索フィールドをAppBarの下に追加
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'タスク名を検索...',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterTasks();
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      // 画面のメインコンテンツ。タスクリストを表示するためにListView.builderを使用
      body: _filteredTasks.isEmpty && _searchController.text.isNotEmpty
          ? const Center(
              child: Text('検索条件に一致するタスクはありません。'),
            )
          : ListView.builder(
              itemCount: _filteredTasks.length, // ★変更: フィルタリングされたリストを使用
              // 各リスト項目（タスク）を構築するためのビルダー関数
              itemBuilder: (context, index) {
                // 現在のインデックスに対応するタスク情報を取得
                final task = _filteredTasks[index]; // ★変更: フィルタリングされたリストから取得
                final bool isFavorite =
                    task['isFavorite'] ?? false; // お気に入り状態を取得
                final String? createdAtString = task['createdAt']; // 作成日時を取得

                String formattedDate = '';
                if (createdAtString != null) {
                  try {
                    final DateTime createdAt = DateTime.parse(createdAtString);
                    // 日付フォーマットをyyyy/MM/dd HH:mm に設定
                    formattedDate =
                        DateFormat('yyyy/MM/dd HH:mm').format(createdAt);
                  } catch (e) {
                    print('Error parsing date: $e');
                  }
                }

                // 各タスクを表示するためのCardウィジェット
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8), // Cardの外側の余白
                  shape: RoundedRectangleBorder(
                    // Cardの形状を設定
                    borderRadius: BorderRadius.circular(10), // 角を丸くする
                    side: const BorderSide(color: Colors.grey), // 枠線の色を設定
                  ),
                  elevation: 2, // Cardの影の深さ
                  // Card内のリスト項目を表示するためのListTileウィジェット
                  child: ListTile(
                    // ★追加: お気に入りボタン
                    leading: IconButton(
                      icon: Icon(
                        isFavorite
                            ? Icons.star // お気に入りの場合
                            : Icons.star_border, // お気に入りでない場合
                        color: isFavorite
                            ? Colors.amber // お気に入りの場合は金色
                            : Colors.grey, // お気に入りでない場合は灰色
                      ),
                      onPressed: () =>
                          _toggleFavorite(index), // クリックでお気に入り状態を切り替え
                    ),
                    title: Text(
                      task['title'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    // ★変更: subtitleに説明と日付を表示
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (formattedDate.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              formattedDate,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                    onTap: () => _navigateToEditTaskPage(index), // タップで編集
                    // リスト項目の末尾に表示されるウィジェット (削除ボタン)
                    trailing: IconButton(
                      icon: const Icon(Icons.delete), // 削除アイコン
                      // ★変更: お気に入り状態の場合、onPressedをnullにしてボタンを無効化
                      onPressed: isFavorite
                          ? null // お気に入りの場合は無効
                          : () => _deleteTask(index), // ★変更: 削除メソッドを呼び出し
                    ),
                  ),
                );
              },
            ),
      // 画面右下に表示されるフローティングアクションボタン
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTaskPage, // ボタンが押されたらタスク追加ページへ遷移するメソッドを呼び出す
        tooltip: 'タスクの追加',
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
