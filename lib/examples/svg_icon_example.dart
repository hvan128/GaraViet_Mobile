import 'package:flutter/material.dart';
import '../widgets/svg_icon.dart';

/// Ví dụ sử dụng thư viện SvgIcon
class SvgIconExample extends StatelessWidget {
  const SvgIconExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG Icon Examples'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ví dụ cơ bản
            _buildSection(
              title: 'Ví dụ cơ bản',
              children: [
                Row(
                  children: [
                    const SvgIcon(
                      svgPath: 'assets/icons_final/eye_close.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 16),
                    const SvgIcon(
                      svgPath: 'assets/icons_final/star.svg',
                      width: 32,
                      height: 32,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ví dụ với màu sắc
            _buildSection(
              title: 'Ví dụ với màu sắc',
              children: [
                Row(
                  children: [
                    const SvgIcon(
                      svgPath: 'assets/icons_final/star.svg',
                      size: 24,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 16),
                    const SvgIcon(
                      svgPath: 'assets/icons_final/star.svg',
                      size: 24,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    const SvgIcon(
                      svgPath: 'assets/icons_final/star.svg',
                      size: 24,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ví dụ với extension methods
            _buildSection(
              title: 'Sử dụng Extension Methods',
              children: [
                Row(
                  children: [
                    'assets/icons_final/eye_close.svg'.toSvgIconSized(
                      size: 20,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    'assets/icons_final/star.svg'.toSvgIcon(
                      size: 28,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ví dụ với predefined sizes
            _buildSection(
              title: 'Sử dụng Predefined Sizes',
              children: [
                Row(
                  children: [
                    const SvgIcon(
                      svgPath: 'assets/icons_final/star.svg',
                      size: SvgIconSizes.xs,
                      color: SvgIconColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const SvgIcon(
                      svgPath: 'assets/icons_final/star.svg',
                      size: SvgIconSizes.sm,
                      color: SvgIconColors.success,
                    ),
                    const SizedBox(width: 8),
                    const SvgIcon(
                      svgPath: 'assets/icons_final/star.svg',
                      size: SvgIconSizes.md,
                      color: SvgIconColors.warning,
                    ),
                    const SizedBox(width: 8),
                    const SvgIcon(
                      svgPath: 'assets/icons_final/star.svg',
                      size: SvgIconSizes.lg,
                      color: SvgIconColors.error,
                    ),
                    const SizedBox(width: 8),
                    const SvgIcon(
                      svgPath: 'assets/icons_final/star.svg',
                      size: SvgIconSizes.xl,
                      color: SvgIconColors.info,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ví dụ với alignment và fit
            _buildSection(
              title: 'Ví dụ với Alignment và BoxFit',
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const SvgIcon(
                    svgPath: 'assets/icons_final/star.svg',
                    size: 40,
                    color: Colors.blue,
                    alignment: Alignment.topLeft,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ví dụ trong ListTile
            _buildSection(
              title: 'Sử dụng trong ListTile',
              children: [
                ListTile(
                  leading: const SvgIcon(
                    svgPath: 'assets/icons_final/star.svg',
                    size: 24,
                    color: Colors.amber,
                  ),
                  title: const Text('Icon với ListTile'),
                  subtitle: const Text('Ví dụ sử dụng SVG icon trong ListTile'),
                  trailing: const SvgIcon(
                    svgPath: 'assets/icons_final/eye_close.svg',
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ví dụ với Button
            _buildSection(
              title: 'Sử dụng trong Button',
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const SvgIcon(
                    svgPath: 'assets/icons_final/star.svg',
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text('Button với Icon'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const SvgIcon(
                    svgPath: 'assets/icons_final/eye_close.svg',
                    size: 18,
                    color: Colors.blue,
                  ),
                  label: const Text('Outlined Button'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

