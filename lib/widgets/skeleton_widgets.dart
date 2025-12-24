import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VehicleCardSkeleton extends StatelessWidget {
  final bool isSmall;

  const VehicleCardSkeleton({Key? key, this.isSmall = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: isSmall ? 280 : 350,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem skeleton
            Container(
              height: isSmall ? 200 : 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Título skeleton
            Container(
              height: 16,
              width: double.infinity,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
            // Preço skeleton
            Container(
              height: 14,
              width: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 4),
            // Detalhes skeleton
            Row(
              children: [
                Container(
                  height: 12,
                  width: 60,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Container(
                  height: 12,
                  width: 80,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Localização skeleton
            Container(
              height: 12,
              width: 100,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class VehicleListSkeleton extends StatelessWidget {
  final int itemCount;

  const VehicleListSkeleton({Key? key, this.itemCount = 5}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              children: [
                // Imagem skeleton
                Container(
                  height: 100,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                // Conteúdo skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            height: 12,
                            width: 50,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 16),
                          Container(
                            height: 12,
                            width: 70,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}