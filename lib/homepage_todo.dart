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
  // タスクのリストを定義。各タスクは「タイトル」「内容」「お気に入り状態」「作成日時」「締め切り日時」を持つMapとして保持
  List<Map<String, dynamic>> tasks = [];
  // 検索結果を表示するためのリスト
  List<Map<String, dynamic>> _filteredTasks = [];
  // 検索キーワードを保持するためのコントローラー
  final TextEditingController _searchController = TextEditingController();

  // ★: ウィジェットが最初に作成されるときに呼び出される
  @override
  void initState() {
    super.initState();
    _loadTasks(); // ★: アプリ起動時に保存されたタスクを読み込む
    // 検索フィールドのテキスト変更をリッスン
    _searchController.addListener(_filterTasks);
  }

  // ★: ウィジェットが破棄されるときに呼び出される
  @override
  void dispose() {
    _searchController.removeListener(_filterTasks);
    _searchController.dispose();
    super.dispose();
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
          // deadlineがnullの場合には何も設定しない（任意項目なので）
          return taskMap;
        }).toList();
        _sortTasks(); // ★: ロード時にも並び替える
        _filterTasks(); // ★: ロード後、全タスクを表示するためにフィルタリングを実行
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

  // ★変更: タスクを並び替えるメソッド（締め切り日時でのソート追加）
  void _sortTasks() {
    setState(() {
      tasks.sort((a, b) {
        final bool isAFavorite = a['isFavorite'] ?? false;
        final bool isBFavorite = b['isFavorite'] ?? false;

        // 1. お気に入り（trueが優先）
        if (isAFavorite && !isBFavorite) {
          return -1;
        } else if (!isAFavorite && isBFavorite) {
          return 1;
        } else {
          // お気に入り状態が同じ場合

          final DateTime? deadlineA =
              a['deadline'] != null ? DateTime.parse(a['deadline']) : null;
          final DateTime? deadlineB =
              b['deadline'] != null ? DateTime.parse(b['deadline']) : null;

          // 2. 締め切り日時（設定されているものが優先、近いものが優先）
          if (deadlineA != null && deadlineB != null) {
            return deadlineA.compareTo(deadlineB); // 近い期限を先頭に
          } else if (deadlineA != null) {
            return -1; // deadlineAのみ設定されていればAを優先
          } else if (deadlineB != null) {
            return 1; // deadlineBのみ設定されていればBを優先
          } else {
            // 締め切り日時も設定されていない場合
            final DateTime? timeA =
                a['createdAt'] != null ? DateTime.parse(a['createdAt']) : null;
            final DateTime? timeB =
                b['createdAt'] != null ? DateTime.parse(b['createdAt']) : null;

            // 3. 作成日時（新しいものが優先）
            if (timeA != null && timeB != null) {
              return timeB.compareTo(timeA); // 新しいものを先頭に
            } else if (timeA != null) {
              return -1;
            } else if (timeB != null) {
              return 1;
            }
            return 0; // すべて同じ場合は順序を変えない
          }
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

// ★変更: タスク追加ページへ遷移する非同期メソッド（締め切り日時を扱う）
  void _navigateToAddTaskPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskPage()),
    );
    if (result != null && result is Map<String, dynamic>) {
      // dynamicに変更
      setState(() {
        tasks.add({
          'title': result['title']!,
          'description': result['description']!,
          'isFavorite': false,
          'createdAt': DateTime.now().toIso8601String(),
          'deadline': result['deadline'], // ★追加: deadlineを保存
        });
      });
      _sortTasks();
      _filterTasks();
      _saveTasks();
    }
  }

  // ★変更: タスク編集ページへ遷移する非同期メソッド（締め切り日時を扱う）
  void _navigateToEditTaskPage(int index) async {
    final originalTask = _filteredTasks[index];
    final originalIndexInTasks = tasks.indexOf(originalTask);

    if (originalIndexInTasks == -1) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskPage(
          initialTitle: originalTask['title'] ?? '',
          initialDescription: originalTask['description'] ?? '',
          initialDeadline: originalTask['deadline'], // ★追加: deadlineを渡す
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic>) {
      // dynamicに変更
      setState(() {
        tasks[originalIndexInTasks] = {
          'title': result['title']!,
          'description': result['description']!,
          'isFavorite': originalTask['isFavorite'] ?? false,
          'createdAt': originalTask['createdAt'],
          'deadline': result['deadline'], // ★追加: deadlineを更新
        };
      });
      _sortTasks();
      _filterTasks();
      _saveTasks();
    }
  }

  // ★変更: お気に入り状態を切り替えるメソッド
  void _toggleFavorite(int index) {
    final originalTask = _filteredTasks[index];
    final originalIndexInTasks = tasks.indexOf(originalTask);

    if (originalIndexInTasks == -1) return;

    setState(() {
      tasks[originalIndexInTasks]['isFavorite'] =
          !(tasks[originalIndexInTasks]['isFavorite'] ?? false);
    });
    _sortTasks();
    _filterTasks();
    _saveTasks();
  }

  // ★変更: タスク削除メソッド（確認ダイアログ追加）
  void _deleteTask(int index) {
    final originalTask = _filteredTasks[index];
    final originalIndexInTasks = tasks.indexOf(originalTask);

    if (originalIndexInTasks == -1) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('タスクの削除'),
          content: Text('「${originalTask['title']}」を削除してもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('削除'),
              onPressed: () {
                setState(() {
                  tasks.removeAt(originalIndexInTasks);
                });
                _filterTasks();
                _saveTasks();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todoリスト'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
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
      body: _filteredTasks.isEmpty && _searchController.text.isEmpty
          ? const Center(
              child: Text('タスクがありません。'),
            )
          : _filteredTasks.isEmpty && _searchController.text.isNotEmpty
              ? const Center(
                  child: Text('検索条件に一致するタスクはありません。'),
                )
              : ListView.builder(
                  itemCount: _filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = _filteredTasks[index];
                    final bool isFavorite = task['isFavorite'] ?? false;
                    final String? createdAtString = task['createdAt'];
                    final String? deadlineString =
                        task['deadline']; // ★追加: deadlineを取得

                    String formattedCreatedAt = '';
                    if (createdAtString != null) {
                      try {
                        final DateTime createdAt =
                            DateTime.parse(createdAtString);
                        formattedCreatedAt =
                            DateFormat('yyyy/MM/dd HH:mm').format(createdAt);
                      } catch (e) {
                        print('Error parsing creation date: $e');
                      }
                    }

                    String formattedDeadline = ''; // ★追加: deadlineのフォーマット用変数
                    if (deadlineString != null) {
                      try {
                        final DateTime deadline =
                            DateTime.parse(deadlineString);
                        formattedDeadline =
                            '期限: ${DateFormat('yyyy/MM/dd HH:mm').format(deadline)}';
                      } catch (e) {
                        print('Error parsing deadline date: $e');
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: isFavorite ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(index),
                        ),
                        title: Text(
                          task['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['description'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (formattedCreatedAt.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  formattedCreatedAt,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            if (formattedDeadline.isNotEmpty) // ★追加: 期限があれば表示
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  formattedDeadline,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.redAccent), // 期限は赤字に
                                ),
                              ),
                          ],
                        ),
                        onTap: () => _navigateToEditTaskPage(index),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed:
                              isFavorite ? null : () => _deleteTask(index),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTaskPage,
        tooltip: 'タスクの追加',
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}
