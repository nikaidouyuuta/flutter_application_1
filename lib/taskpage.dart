import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日付フォーマットのために追加

// TaskPageウィジェットを定義。状態を持つのでStatefulWidgetに変更
class TaskPage extends StatefulWidget {
  // ★変更: StatelessWidgetからStatefulWidgetに
  final String? initialTitle;
  final String? initialDescription;
  final String? initialDeadline; // ★追加: 初期締め切り日時

  const TaskPage({
    super.key,
    this.initialTitle,
    this.initialDescription,
    this.initialDeadline, // ★追加
  });

  @override
  State<TaskPage> createState() => _TaskPageState(); // ★追加
}

class _TaskPageState extends State<TaskPage> {
  // ★追加
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDeadline; // ★追加: 選択された締め切り日時

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    if (widget.initialDeadline != null) {
      _selectedDeadline = DateTime.parse(widget.initialDeadline!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ★追加: 日時ピッカーを表示して締め切り日時を設定するメソッド
  Future<void> _pickDeadline() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate:
          DateTime.now().subtract(const Duration(days: 365 * 5)), // 5年前まで
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)), // 5年後まで
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(_selectedDeadline ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // ★追加: 締め切り日時をクリアするメソッド
  void _clearDeadline() {
    setState(() {
      _selectedDeadline = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDeadline = '';
    if (_selectedDeadline != null) {
      formattedDeadline =
          DateFormat('yyyy/MM/dd HH:mm').format(_selectedDeadline!);
    }

    // 画面全体の基本的な構造を提供するScaffoldウィジェット
    return Scaffold(
      // アプリケーションバーの設定
      appBar: AppBar(
        title: const Text('タスク追加 / 編集'), // アプリバーのタイトル
        backgroundColor: Theme.of(context).primaryColor, // AppBarの背景色を設定
        foregroundColor: Colors.white, // AppBarのテキスト・アイコン色を設定
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
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'タスク名',
                border: OutlineInputBorder(), // 枠線を表示
              ),
            ),
            const SizedBox(height: 20),
            // タスク内容を入力するためのテキストフィールド
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'タスク内容',
                border: OutlineInputBorder(),
              ),
              maxLines: 4, // 複数行対応
            ),
            const SizedBox(height: 20),
            // ★追加: 締め切り日時設定ボタン
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDeadline,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('締め切り日時を設定'),
                  ),
                ),
                if (_selectedDeadline != null) // 締め切りが設定されていればクリアボタンを表示
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearDeadline,
                    tooltip: '締め切りをクリア',
                  ),
              ],
            ),
            if (_selectedDeadline != null) // 選択された締め切り日時を表示
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '選択中の締め切り: $formattedDeadline',
                  style:
                      const TextStyle(fontSize: 16, color: Colors.blueAccent),
                ),
              ),
            const SizedBox(height: 20),
            // 保存ボタン
            ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _descriptionController.text.isNotEmpty) {
                  Navigator.pop(context, {
                    'title': _titleController.text,
                    'description': _descriptionController.text,
                    'deadline': _selectedDeadline
                        ?.toIso8601String(), // ★変更: deadlineをISO8601形式で返す
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
