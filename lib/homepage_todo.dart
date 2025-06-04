import 'package:flutter/material.dart';
import 'package:flutter_application_1/taskpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// HomePageウィジェットを定義。状態を持つためStatefulWidgetを使用
class HomePage extends StatefulWidget {
  const HomePage({super.key}); // コンストラクタ

  @override
  State<HomePage> createState() => _HomePageState();
}

// HomePageウィジェットの状態を管理するクラス
class _HomePageState extends State<HomePage> {
  // タスクのリストを定義。各タスクは「タイトル」「内容」「お気に入り状態」を持つMapとして保持
  List<Map<String, dynamic>> tasks = [];

  // ★: ウィジェットが最初に作成されるときに呼び出される
  @override
  void initState() {
    super.initState();
    _loadTasks(); // ★: アプリ起動時に保存されたタスクを読み込む
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
          return taskMap;
        }).toList();
        _sortTasks(); // ★: ロード時にも並び替える
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
          // 両方がお気に入り、または両方がお気に入りでない場合は元の順序を維持（またはタイトルなどでソートするなど任意）
          return 0;
        }
      });
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
        // ★変更: 新しいタスクにはisFavorite: false を追加
        tasks.add({
          'title': result['title']!,
          'description': result['description']!,
          'isFavorite': false, // 新規追加タスクはデフォルトでお気に入りではない
        });
      });
      _sortTasks(); // ★: タスク追加後にも並び替える
      _saveTasks(); // ★: タスクが追加されたら、すぐに保存する
    }
  }

  // タスク編集ページへ遷移する非同期メソッド
  void _navigateToEditTaskPage(int index) async {
    final originalTask = tasks[index];
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
        // 既存のタスクのisFavorite状態を保持しつつ更新
        tasks[index] = {
          'title': result['title']!,
          'description': result['description']!,
          'isFavorite': originalTask['isFavorite'] ?? false,
        };
      });
      _sortTasks(); // ★: タスク編集後にも並び替える
      _saveTasks(); // ★: タスクが編集されたら、すぐに保存する
    }
  }

  // ★変更: お気に入り状態を切り替えるメソッド
  void _toggleFavorite(int index) {
    setState(() {
      // isFavoriteの状態を反転させる
      tasks[index]['isFavorite'] = !(tasks[index]['isFavorite'] ?? false);
    });
    _sortTasks(); // ★: お気に入り状態変更後にも並び替える
    _saveTasks(); // ★: お気に入り状態変更を保存する
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
      ),
      // 画面のメインコンテンツ。タスクリストを表示するためにListView.builderを使用
      body: ListView.builder(
        itemCount: tasks.length, // リストの項目数（タスクの数）
        // 各リスト項目（タスク）を構築するためのビルダー関数
        itemBuilder: (context, index) {
          // 現在のインデックスに対応するタスク情報を取得
          final task = tasks[index];
          final bool isFavorite = task['isFavorite'] ?? false; // お気に入り状態を取得

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
                onPressed: () => _toggleFavorite(index), // クリックでお気に入り状態を切り替え
              ),
              title: Text(
                task['title'] ?? '',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                task['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _navigateToEditTaskPage(index), // タップで編集
              // リスト項目の末尾に表示されるウィジェット (削除ボタン)
              trailing: IconButton(
                icon: const Icon(Icons.delete), // 削除アイコン
                // ★変更: お気に入り状態の場合、onPressedをnullにしてボタンを無効化
                onPressed: isFavorite
                    ? null // お気に入りの場合は無効
                    : () {
                        // ボタンが押された時の処理
                        setState(() {
                          tasks.removeAt(index);
                        });
                        _saveTasks(); // ★: タスクが削除されたら、すぐに保存する
                      },
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
