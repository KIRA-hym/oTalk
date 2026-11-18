import 'package:flutter/material.dart';

class QuickMemberSelectionDialog extends StatefulWidget {
  final List<String> existingPoolNames;
  final List<String> alreadySelectedNames;

  const QuickMemberSelectionDialog({
    super.key,
    required this.existingPoolNames,
    required this.alreadySelectedNames,
  });

  @override
  State<QuickMemberSelectionDialog> createState() =>
      _QuickMemberSelectionDialogState();
}

class _QuickMemberSelectionDialogState
    extends State<QuickMemberSelectionDialog> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitTypedName() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final unselectedFromPool = widget.existingPoolNames
        .where((name) => !widget.alreadySelectedNames.contains(name))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '참여 인원 추가',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    focusNode: _focusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '이름/닉네임 입력 (띄어쓰기·쉼표로 여러 명 가능)',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (_) => _submitTypedName(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitTypedName,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '추가',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (unselectedFromPool.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '다른 차수에 입력된 인원 클릭해서 추가',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unselectedFromPool
                    .map(
                      (name) => ActionChip(
                        avatar: const Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color: Colors.amber,
                        ),
                        label: Text(name),
                        onPressed: () => Navigator.pop(context, name),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
