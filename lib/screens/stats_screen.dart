import 'package:flutter/material.dart';
import '../core/constants.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('?µÍ≥Ñ Î∞??Ä?úÎ≥¥??),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('?î• ?¥Îã¨??Ï∞∏Ïó¨??, style: AppTextStyles.h2),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRankItem(1, '?çÍ∏∏??, '5??),
                      _buildRankItem(2, 'ÍπÄÏ≤†Ïàò', '4??),
                      _buildRankItem(3, '?¥ÏòÅ??, '4??),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('?ìà Î™®ÏûÑ ?µÍ≥Ñ Ï§ÄÎπÑÏ§ë', style: AppTextStyles.h2),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Center(
                  child: Text('Ï∞®Ìä∏Í∞Ä ?úÏãú???ÅÏó≠?ÖÎãà??', style: AppTextStyles.body2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankItem(int rank, String name, String count) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: rank == 1 ? AppColors.primary : AppColors.divider,
          radius: 30,
          child: Text(
            '$rank??,
            style: TextStyle(
              color: rank == 1 ? AppColors.background : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard'
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(name, style: AppTextStyles.body1),
        const SizedBox(height: 4),
        Text(count, style: AppTextStyles.body2.copyWith(color: AppColors.primary)),
      ],
    );
  }
}
