import 'package:flutter/material.dart';
import 'package:flutter_application_1/taskpage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // タスク名と内容を持つマップのリストに変更
  List<Map<String, String>> tasks = [];

  void _navigateToAddTaskPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskPage()),
    );
    // resultがMapなら追加
    if (result != null && result is Map<String, String>) {
      setState(() {
        tasks.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todoリスト'),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.grey),
            ),
            elevation: 2,
            child: ListTile(
              title: Text(task['title'] ?? ''),
              subtitle: Text(task['description'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    tasks.removeAt(index);
                  });
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTaskPage,
        tooltip: 'タスクの追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
