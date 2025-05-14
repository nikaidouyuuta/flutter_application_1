import 'package:flutter/material.dart';

// TaskPageウィジェットを定義。状態を持たないのでStatelessWidgetを使用
class TaskPage extends StatelessWidget {
  final String? initialTitle;
  final String? initialDescription;

  const TaskPage({
    super.key,
    this.initialTitle,
    this.initialDescription,
  }); // コンストラクタ

  @override
  Widget build(BuildContext context) {
    // テキストフィールドの入力値を制御するためのコントローラーを作成
    final TextEditingController titleController =
        TextEditingController(text: initialTitle ?? ''); // タスク名入力用コントローラー
    final TextEditingController descriptionController = TextEditingController(
        text: initialDescription ?? ''); // タスク内容入力用コントローラー

    // 画面全体の基本的な構造を提供するScaffoldウィジェット
    return Scaffold(
      // アプリケーションバーの設定
      appBar: AppBar(
        title: const Text('タスク追加 / 編集'), // アプリバーのタイトル
      ),
      // 画面のメインコンテンツ。上下左右に16ピクセルの余白を追加
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // 子要素を縦方向に並べるColumnウィジェット
        child: Column(
          // childrenリストにUI要素を配置
          children: [
            // タスク名を入力するためのテキストフィールド
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'タスク名',
                border: OutlineInputBorder(), // 枠線を表示
              ),
            ),
            const SizedBox(height: 20),
            // タスク内容を入力するためのテキストフィールド
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'タスク内容',
                border: OutlineInputBorder(),
              ),
              maxLines: 4, // 複数行対応
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'title': titleController.text,
                    'description': descriptionController.text,
                  });
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
