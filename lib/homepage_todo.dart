import 'package:flutter/material.dart';
import 'package:flutter_application_1/taskpage.dart';
import 'package:shared_preferences/shared_preferences.dart'; // shared_preferencesをインポート
import 'dart:convert'; // JSONエンコード/デコードのためにインポート

// HomePageウィジェットを定義。状態を持つためStatefulWidgetを使用
class HomePage extends StatefulWidget {
  const HomePage({super.key}); // コンストラクタ

  @override
  State<HomePage> createState() => _HomePageState();
}

// HomePageウィジェットの状態を管理するクラス
class _HomePageState extends State<HomePage> {
  // タスクのリストを定義。各タスクは「タイトル」と「内容」を持つMapとして保持
  List<Map<String, String>> tasks = [];

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
        // デコードしたリストをList<Map<String, String>>型に変換し、tasksリストを更新
        // .from(item) を使うことで、dynamic型からMap<String, String>への安全なキャストを行う
        tasks =
            decodedTasks.map((item) => Map<String, String>.from(item)).toList();
      });
    }
  }

  // ★: SharedPreferencesにタスクを保存する非同期メソッド
  Future<void> _saveTasks() async {
    final prefs =
        await SharedPreferences.getInstance(); // SharedPreferencesのインスタンスを取得
    // 現在のtasksリストをJSON形式の文字列にエンコードして保存
    // Mapのリストは直接保存できないため、JSON文字列に変換する必要がある
    await prefs.setString('tasks', json.encode(tasks));
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
        // 取得したタスク情報をリストに追加
        tasks.add(result);
      });
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
        tasks[index] = result; // 指定位置のタスクを更新
      });
      _saveTasks(); // ★: タスクが編集されたら、すぐに保存する
    }
  }

  @override
  Widget build(BuildContext context) {
    // 画面全体の基本的な構造を提供するScaffoldウィジェット
    return Scaffold(
      // アプリケーションバーの設定
      appBar: AppBar(
        title: const Text('Todoリスト'), // アプリバーのタイトル
        // ★: AppBarの背景色をテーマのプライマリーカラーに設定
        backgroundColor: Theme.of(context).primaryColor,
        // ★変更: AppBarのテキストとアイコンの色を白に設定
        foregroundColor: Colors.white,
      ),
      // 画面のメインコンテンツ。タスクリストを表示するためにListView.builderを使用
      body: ListView.builder(
        itemCount: tasks.length, // リストの項目数（タスクの数）
        // 各リスト項目（タスク）を構築するためのビルダー関数
        itemBuilder: (context, index) {
          // 現在のインデックスに対応するタスク情報を取得
          final task = tasks[index];

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
              title: Text(
                task['title'] ?? '',
                // ★変更: タイトルテキストのスタイルを太字、サイズ16に設定
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              // タスクのタイトルを表示 (nullの場合は空文字列)
              subtitle: Text(
                task['description'] ?? '',
                maxLines: 2, // ★: サブタイトルは最大2行まで表示
                overflow: TextOverflow.ellipsis, // ★: 2行を超えたら省略記号(...)を表示
              ), // タスクの内容を表示 (nullの場合は空文字列)
              onTap: () => _navigateToEditTaskPage(index), // タップで編集
              // リスト項目の末尾に表示されるウィジェット (削除ボタン)
              trailing: IconButton(
                icon: const Icon(Icons.delete), // 削除アイコン
                onPressed: () {
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
        // ★: ボタンの背景色をテーマのプライマリーカラーに設定
        backgroundColor: Theme.of(context).primaryColor,
        // ★: ボタンのアイコン色を白に設定
        foregroundColor: Colors.white,
      ),
    );
  }
}
