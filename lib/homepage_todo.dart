import 'package:flutter/material.dart';
import 'package:flutter_application_1/taskpage.dart';

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
    }
  }

  @override
  Widget build(BuildContext context) {
    // 画面全体の基本的な構造を提供するScaffoldウィジェット
    return Scaffold(
      // アプリケーションバーの設定
      appBar: AppBar(
        title: const Text('Todoリスト'), // アプリバーのタイトル
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
              title: Text(task['title'] ?? ''), // タスクのタイトルを表示 (nullの場合は空文字列)
              subtitle:
                  Text(task['description'] ?? ''), // タスクの内容を表示 (nullの場合は空文字列)
              onTap: () => _navigateToEditTaskPage(index), // タップで編集
              // リスト項目の末尾に表示されるウィジェット (削除ボタン)
              trailing: IconButton(
                icon: const Icon(Icons.delete), // 削除アイコン
                onPressed: () {
                  // ボタンが押された時の処理
                  setState(() {
                    tasks.removeAt(index);
                  });
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
      ),
    );
  }
}
