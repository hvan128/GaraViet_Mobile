import 'package:flutter/material.dart';
import 'status_library.dart';

// Ví dụ sử dụng Status Library
class StatusExampleScreen extends StatelessWidget {
  const StatusExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Library Example'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị tất cả trạng thái như trong ảnh
            const AllStatusWidget(),
            
            const SizedBox(height: 32),
            
            // Ví dụ hiển thị trạng thái đơn lẻ
            const Text(
              'Trạng thái đơn lẻ:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusWidget(
                  status: QuotationStatus.waitingForQuotation,
                  type: StatusType.quotation,
                ),
                StatusWidget(
                  status: QuotationStatus.depositPaid,
                  type: StatusType.quotation,
                ),
                StatusWidget(
                  status: RequestStatus.accepted,
                  type: StatusType.request,
                ),
                StatusWidget(
                  status: RequestStatus.completed,
                  type: StatusType.request,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Ví dụ sử dụng utility functions
            const Text(
              'Utility Functions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            _buildUtilityExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilityExample() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trạng thái báo giá từ value 1: ${StatusUtils.getQuotationStatusByValue(1).displayName}'),
          const SizedBox(height: 8),
          Text('Có thể chuyển từ "Chờ báo giá" sang "Chờ lên lịch": ${StatusUtils.canTransitionQuotationStatus(1, 2)}'),
          const SizedBox(height: 8),
          Text('Các trạng thái tiếp theo có thể: ${StatusUtils.getNextPossibleQuotationStatuses(1).map((s) => s.displayName).join(", ")}'),
          const SizedBox(height: 8),
          Text('Màu sắc của trạng thái "Đã cọc": ${StatusUtils.getStatusColors(4, StatusType.quotation)}'),
        ],
      ),
    );
  }
}

// Ví dụ sử dụng trong một widget khác
class QuotationCard extends StatelessWidget {
  final int quotationStatus;
  final int requestStatus;

  const QuotationCard({
    Key? key,
    required this.quotationStatus,
    required this.requestStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin báo giá',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Hiển thị trạng thái báo giá
            Row(
              children: [
                const Text('Trạng thái báo giá: '),
                StatusWidget(
                  status: quotationStatus,
                  type: StatusType.quotation,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Hiển thị trạng thái yêu cầu
            Row(
              children: [
                const Text('Trạng thái yêu cầu: '),
                StatusWidget(
                  status: requestStatus,
                  type: StatusType.request,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
